# frozen_string_literal: true

module Api
  module V1
    class DteController < BaseController
      # Orquesta el pipeline de emisión DTE en etapas reutilizables:
      #
      #   1. preparar_items      → enriquece producto_id con datos de BD e impuestos
      #   2. ClasificadorItems    → reparte ítems en páginas según espacio PDF
      #   3. AsignadorFolios      → asigna folio CAF y rsask por página
      #   4. construir_estructura → arma emisor/receptor/totales por página
      #   5. GeneradorXml         → serializa EnvioDTE (sin firmar)
      #   6. Firmador             → inserta CAF, firma TED y firma SetDTE (solo firmar_xml)
      #
      # Endpoints de prueba: test_clasificacion, test_folios
      # Endpoints productivos: preparar → generar_xml → firmar_xml → generar

      # Temporalmente sin autenticación para pruebas (generar sí requiere JWT)
      skip_before_action :authenticate_request!, only: [:test_clasificacion, :test_folios, :preparar, :generar_xml, :firmar_xml]
      # Endpoint de prueba para verificar la clasificación de items en páginas
      #
      # Body esperado:
      # {
      #   "items": [
      #     { "cantidad": 2, "glosa": "Producto A", "precio_unitario": 1000 },
      #     { "cantidad": 1, "glosa": "Producto B", "precio_unitario": 2000 }
      #   ]
      # }
      #
      def test_clasificacion
        items = params[:items] || []
        archivo_temp = nil

        if items.empty?
          return render json: {
            success: false,
            error: 'Debe enviar al menos un item'
          }, status: :unprocessable_entity
        end

        # Convertir a array de hashes con símbolos
        items_array = items.map do |item|
          {
            cantidad: item[:cantidad] || item['cantidad'],
            glosa: item[:glosa] || item['glosa'],
            precio_unitario: item[:precio_unitario] || item['precio_unitario'],
            codigo: item[:codigo] || item['codigo'] || 'INT1'
          }
        end

        # Archivo temporal para el cálculo
        archivo_temp = Rails.root.join('tmp', "test_clasificacion_#{Time.current.to_i}.pdf")

        # Ejecutar clasificación
        resultado = Dte::ClasificadorItems.call(
          items: items_array,
          archivo: archivo_temp.to_s
        )

        render json: {
          success: true,
          data: {
            total_items: items_array.count,
            total_paginas: resultado[:total_paginas],
            items_paginados: resultado[:items],
            paginas: resultado[:paginas]
          }
        }, status: :ok

      rescue StandardError => e
        render json: {
          success: false,
          error: e.message,
          backtrace: Rails.env.development? ? e.backtrace.first(5) : nil
        }, status: :internal_server_error
      ensure
        limpiar_archivos_temporales([archivo_temp]) if archivo_temp
      end

      # POST /api/v1/dte/test_folios
      # Endpoint de prueba para verificar la asignación de folios
      #
      # Body esperado:
      # {
      #   "empresa_id": 1,
      #   "tipo_documento": 33,
      #   "cantidad_paginas": 2
      # }
      #
      def test_folios
        empresa_id = params[:empresa_id]
        tipo_documento = params[:tipo_documento] || 33
        cantidad_paginas = (params[:cantidad_paginas] || 1).to_i

        unless empresa_id
          return render json: {
            success: false,
            error: 'empresa_id es requerido'
          }, status: :unprocessable_entity
        end

        # Crear páginas simuladas
        paginas = (1..cantidad_paginas).map do |n|
          { pagina: n, folio: -1, archivo_caf: nil }
        end

        # Ejecutar asignación de folios
        resultado = Dte::AsignadorFolios.call(
          paginas: paginas,
          empresa_id: empresa_id.to_i,
          tipo_documento: tipo_documento.to_i
        )

        render json: {
          success: resultado[:disponibles],
          data: {
            paginas: resultado[:paginas],
            folios_usados: resultado[:folios_usados],
            todos_disponibles: resultado[:disponibles]
          },
          error: resultado[:error]
        }, status: resultado[:disponibles] ? :ok : :unprocessable_entity

      rescue StandardError => e
        render json: {
          success: false,
          error: e.message,
          backtrace: Rails.env.development? ? e.backtrace.first(5) : nil
        }, status: :internal_server_error
      end

      # POST /api/v1/dte/preparar
      # Ejecuta etapas 1-4 del pipeline y devuelve la estructura lista para XML,
      # sin generar archivo ni consumir folios en BD (solo los reserva en memoria).
      #
      # Body esperado:
      # {
      #   "empresa_id": 101,
      #   "tipo_documento": 33,
      #   "receptor": {
      #     "rut": "12345678-9",
      #     "razon_social": "Cliente Ejemplo",
      #     "giro": "Servicios",
      #     "direccion": "Av. Principal 123",
      #     "email": "cliente@ejemplo.cl"
      #   },
      #   "items": [
      #     { "producto_id": 445, "cantidad": 2 },
      #     { "producto_id": 444, "cantidad": 1 }
      #   ]
      # }
      #
      def preparar
        archivo_temp = nil
        
        # Validaciones
        errores = validar_params_preparar
        return render json: { success: false, errors: errores }, status: :unprocessable_entity if errores.any?

        empresa = Empresa.find_by(id: params[:empresa_id])
        return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found unless empresa

        # Etapa 1: producto_id → ítem con precio, neto, afecto e impuestos
        items_array = preparar_items(params[:items])

        # Etapa 2: simula render PDF (Prawn) para saber cuántos ítems caben por página
        archivo_temp = Rails.root.join('tmp', "dte_#{empresa.id}_#{Time.current.to_i}.pdf")
        resultado_clasificacion = Dte::ClasificadorItems.call(
          items: items_array,
          archivo: archivo_temp.to_s
        )

        # Etapa 3: asigna folio + rsask del CAF a cada página resultante
        resultado_folios = Dte::AsignadorFolios.call(
          paginas: resultado_clasificacion[:paginas],
          empresa_id: empresa.id,
          tipo_documento: params[:tipo_documento].to_i
        )

        unless resultado_folios[:disponibles]
          return render json: {
            success: false,
            error: resultado_folios[:error],
            fase: 'asignacion_folios'
          }, status: :unprocessable_entity
        end

        # Etapa 4: agrupa ítems por página y calcula totales (neto, IVA, total)
        estructura_dte = construir_estructura_dte(
          empresa: empresa,
          receptor: params[:receptor],
          tipo_documento: params[:tipo_documento].to_i,
          items: resultado_clasificacion[:items],
          paginas: resultado_folios[:paginas]
        )

        render json: {
          success: true,
          message: 'DTE preparado correctamente',
          data: estructura_dte,
          resumen: {
            empresa: empresa.razon_social,
            tipo_documento: params[:tipo_documento],
            total_items: items_array.count,
            total_paginas: resultado_folios[:paginas].count,
            folios_asignados: resultado_folios[:folios_usados]
          }
        }, status: :ok

      rescue StandardError => e
        render json: {
          success: false,
          error: e.message,
          backtrace: Rails.env.development? ? e.backtrace.first(10) : nil
        }, status: :internal_server_error
      ensure
        limpiar_archivos_temporales([archivo_temp]) if archivo_temp
      end

      # POST /api/v1/dte/generar_xml
      # Pipeline completo hasta etapa 5: devuelve el XML EnvioDTE sin firmar.
      #
      # Body esperado: igual que /preparar
      # {
      #   "empresa_id": 101,
      #   "tipo_documento": 33,
      #   "receptor": { ... },
      #   "items": [{ "producto_id": 445, "cantidad": 2 }, ...]
      # }
      #
      def generar_xml
        @archivos_temporales = []
        
        # Validaciones
        errores = validar_params_preparar
        return render json: { success: false, errors: errores }, status: :unprocessable_entity if errores.any?

        empresa = Empresa.includes(:acteco_empresas, actecos: []).find_by(id: params[:empresa_id])
        return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found unless empresa

        # Etapas 1-4 (mismo flujo que preparar)
        items_array = preparar_items(params[:items])

        archivo_pdf = Rails.root.join('tmp', "dte_#{empresa.id}_#{Time.current.to_i}.pdf")
        @archivos_temporales << archivo_pdf
        
        resultado_clasificacion = Dte::ClasificadorItems.call(
          items: items_array,
          archivo: archivo_pdf.to_s
        )

        resultado_folios = Dte::AsignadorFolios.call(
          paginas: resultado_clasificacion[:paginas],
          empresa_id: empresa.id,
          tipo_documento: params[:tipo_documento].to_i
        )

        unless resultado_folios[:disponibles]
          return render json: {
            success: false,
            error: resultado_folios[:error],
            fase: 'asignacion_folios'
          }, status: :unprocessable_entity
        end

        estructura_dte = construir_estructura_dte(
          empresa: empresa,
          receptor: params[:receptor],
          tipo_documento: params[:tipo_documento].to_i,
          items: resultado_clasificacion[:items],
          paginas: resultado_folios[:paginas]
        )

        # Actividades económicas del emisor (nodo <Acteco> en el XML)
        actecos = empresa.actecos.map { |a| { codigo: a.codigo, nombre: a.nombre } }

        # Etapa 5: serializa a XML ISO-8859-1 y guarda en tmp/
        resultado_xml = Dte::GeneradorXml.call(
          emisor: estructura_dte[:emisor],
          receptor: estructura_dte[:receptor],
          documento: estructura_dte[:documento],
          paginas: estructura_dte[:paginas],
          rut_envia: params[:rut_envia] || empresa.rut,
          actecos: actecos
        )
        @archivos_temporales << resultado_xml[:archivo] if resultado_xml[:archivo]

        unless resultado_xml[:exitoso]
          return render json: {
            success: false,
            error: resultado_xml[:error],
            fase: 'generacion_xml'
          }, status: :internal_server_error
        end

        # Limpiar archivos antiguos (más de 60 minutos)
        limpiar_archivos_temporales_antiguos(60)

        render json: {
          success: true,
          message: 'XML generado correctamente',
          data: {
            total_documentos: resultado_xml[:total_documentos],
            folios_usados: resultado_folios[:folios_usados]
          },
          xml: resultado_xml[:xml],
          resumen: {
            empresa: empresa.razon_social,
            tipo_documento: params[:tipo_documento],
            total_items: items_array.count,
            total_paginas: resultado_folios[:paginas].count
          }
        }, status: :ok

      rescue StandardError => e
        render json: {
          success: false,
          error: e.message,
          backtrace: Rails.env.development? ? e.backtrace.first(10) : nil
        }, status: :internal_server_error
      ensure
        limpiar_archivos_temporales(@archivos_temporales) if @archivos_temporales&.any?
      end

      # POST /api/v1/dte/firmar_xml
      # Pipeline completo hasta etapa 6: genera XML, firma TED (CAF) y firma SetDTE (certificado).
      #
      # Body esperado: mismo que generar_xml
      #
      def firmar_xml
        @archivos_temporales = []

        resultado = emitir_dte_firmado
        return render_resultado_emision(resultado) unless resultado[:success]

        limpiar_archivos_temporales_antiguos(60)

        render json: respuesta_firmar_xml(resultado), status: :ok
      rescue StandardError => e
        render json: error_emision_json(e), status: :internal_server_error
      ensure
        limpiar_archivos_temporales(@archivos_temporales) if @archivos_temporales&.any?
      end

      # POST /api/v1/dte/generar
      # Emisión completa (Variante A): firma + persistencia en BD + marcado de folios.
      # El envío al SII se activa con enviar_sii: true (pendiente de implementación).
      #
      # Body esperado: igual que firmar_xml
      # Requiere autenticación JWT y que el usuario pertenezca a la empresa.
      #
      def generar
        @archivos_temporales = []

        errores = validar_params_preparar
        return render json: { success: false, errors: errores }, status: :unprocessable_entity if errores.any?

        authorize_empresa!(params[:empresa_id])
        return if performed?

        resultado = emitir_dte_firmado
        return render_resultado_emision(resultado) unless resultado[:success]

        resultado_persistencia = nil
        error_post_firma = nil

        ActiveRecord::Base.transaction do
          resultado_persistencia = Dte::PersistidorDocumento.call(
            empresa: resultado[:empresa],
            usuario: current_user,
            tipo_documento: params[:tipo_documento].to_i,
            receptor: params[:receptor],
            paginas: resultado[:resultado_folios][:paginas],
            items: resultado[:items_clasificados]
          )

          unless resultado_persistencia[:success]
            error_post_firma = resultado_persistencia[:error]
            raise ActiveRecord::Rollback
          end

          resultado_marcado = Dte::MarcadorFolios.call(
            empresa_id: resultado[:empresa].id,
            tipo_documento: params[:tipo_documento].to_i,
            folios_numeros: resultado[:resultado_folios][:folios_usados],
            paginas: resultado[:resultado_folios][:paginas]
          )

          unless resultado_marcado[:success]
            error_post_firma = resultado_marcado[:error]
            raise ActiveRecord::Rollback
          end
        end

        if error_post_firma.present?
          return render json: {
            success: false,
            error: error_post_firma,
            fase: 'persistencia_documento',
            advertencia: 'El DTE fue firmado pero no se pudo persistir en BD ni marcar folios'
          }, status: :internal_server_error
        end

        resultado_envio = enviar_al_sii_si_corresponde(resultado)

        limpiar_archivos_temporales_antiguos(60)

        render json: respuesta_generar(resultado, resultado_persistencia, resultado_envio), status: :ok
      rescue StandardError => e
        render json: error_emision_json(e), status: :internal_server_error
      ensure
        limpiar_archivos_temporales(@archivos_temporales) if @archivos_temporales&.any?
      end

      private

      # Pipeline compartido: preparar → clasificar → folios → XML → firmar
      def emitir_dte_firmado
        @archivos_temporales ||= []

        errores = validar_params_preparar
        return fallo_emision(nil, fase: 'validacion', status: :unprocessable_entity, errors: errores) if errores.any?

        empresa = Empresa.includes(:acteco_empresas, actecos: []).find_by(id: params[:empresa_id])
        return fallo_emision('Empresa no encontrada', fase: 'empresa', status: :not_found) unless empresa

        resolucion_certificado = resolver_certificado_firma(empresa)
        unless resolucion_certificado.success?
          return fallo_emision(
            resolucion_certificado.error,
            fase: 'verificacion_certificado',
            status: :unprocessable_entity
          )
        end

        certificado = resolucion_certificado.certificado
        persona_autorizada = resolucion_certificado.persona_autorizada

        items_array = preparar_items(params[:items])

        archivo_pdf = Rails.root.join('tmp', "dte_firma_#{empresa.id}_#{Time.current.to_i}.pdf")
        @archivos_temporales << archivo_pdf

        resultado_clasificacion = Dte::ClasificadorItems.call(
          items: items_array,
          archivo: archivo_pdf.to_s
        )

        resultado_folios = Dte::AsignadorFolios.call(
          paginas: resultado_clasificacion[:paginas],
          empresa_id: empresa.id,
          tipo_documento: params[:tipo_documento].to_i
        )

        unless resultado_folios[:disponibles]
          return fallo_emision(resultado_folios[:error], fase: 'asignacion_folios', status: :unprocessable_entity)
        end

        estructura_dte = construir_estructura_dte(
          empresa: empresa,
          receptor: params[:receptor],
          tipo_documento: params[:tipo_documento].to_i,
          items: resultado_clasificacion[:items],
          paginas: resultado_folios[:paginas]
        )

        actecos = empresa.actecos.map { |a| { codigo: a.codigo, nombre: a.nombre } }

        resultado_xml = Dte::GeneradorXml.call(
          emisor: estructura_dte[:emisor],
          receptor: estructura_dte[:receptor],
          documento: estructura_dte[:documento],
          paginas: estructura_dte[:paginas],
          rut_envia: params[:rut_envia] || empresa.rut,
          actecos: actecos
        )
        @archivos_temporales << resultado_xml[:archivo] if resultado_xml[:archivo]

        unless resultado_xml[:exitoso]
          return fallo_emision(resultado_xml[:error], fase: 'generacion_xml', status: :internal_server_error)
        end

        paginas_para_firma = resultado_folios[:paginas].map do |pag|
          {
            folio: pag[:folio],
            rsask: pag[:rsask],
            rango_folio_id: pag[:rango_folio_id]
          }
        end

        resultado_firma = Dte::Firmador.call(
          xml_string: resultado_xml[:xml],
          empresa_id: empresa.id,
          paginas: paginas_para_firma,
          certificado: certificado
        )

        unless resultado_firma[:success]
          return fallo_emision(resultado_firma[:error], fase: 'firma_digital', status: :internal_server_error)
        end

        timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
        archivo_firmado = Rails.root.join('tmp', "dte_firmado_#{empresa.id}_#{timestamp}.xml")
        File.write(archivo_firmado, resultado_firma[:xml_firmado], encoding: 'ISO-8859-1')

        {
          success: true,
          empresa: empresa,
          certificado: certificado,
          persona_autorizada: persona_autorizada,
          items_array: items_array,
          items_clasificados: resultado_clasificacion[:items],
          resultado_folios: resultado_folios,
          resultado_xml: resultado_xml,
          resultado_firma: resultado_firma,
          archivo_firmado: archivo_firmado.to_s
        }
      end

      def fallo_emision(error, fase:, status:, errors: nil)
        { success: false, error: error, errors: errors, fase: fase, http_status: status }
      end

      def render_resultado_emision(resultado)
        status = resultado[:http_status] || :unprocessable_entity
        payload = { success: false, error: resultado[:error] }
        payload[:fase] = resultado[:fase] if resultado[:fase]
        payload[:errors] = resultado[:errors] if resultado[:errors]
        render json: payload, status: status
      end

      def respuesta_firmar_xml(resultado)
        {
          success: true,
          message: 'DTE generado y firmado correctamente',
          data: {
            archivo_firmado: resultado[:archivo_firmado],
            total_documentos: resultado[:resultado_xml][:total_documentos],
            folios_usados: resultado[:resultado_folios][:folios_usados]
          },
          xml: resultado[:resultado_firma][:xml_firmado],
          resumen: resumen_emision(resultado)
        }
      end

      def respuesta_generar(resultado, resultado_persistencia, resultado_envio)
        {
          success: true,
          message: mensaje_generar(resultado_envio),
          data: {
            archivo_firmado: resultado[:archivo_firmado],
            total_documentos: resultado[:resultado_xml][:total_documentos],
            folios_usados: resultado[:resultado_folios][:folios_usados],
            documentos_emitidos: resultado_persistencia[:documentos].map { |doc| documento_emitido_json(doc) },
            envio_sii: resultado_envio_json(resultado_envio)
          },
          xml: resultado[:resultado_firma][:xml_firmado],
          resumen: resumen_emision(resultado)
        }
      end

      def resumen_emision(resultado)
        persona = resultado[:persona_autorizada]

        {
          empresa: resultado[:empresa].razon_social,
          tipo_documento: params[:tipo_documento],
          total_items: resultado[:items_array].count,
          total_paginas: resultado[:resultado_folios][:paginas].count,
          certificado_usado: resultado[:certificado].id,
          persona_autorizada_id: persona&.id,
          persona_autorizada: persona&.nombre_completo,
          persona_autorizada_rut: persona&.rut
        }
      end

      def resolver_certificado_firma(empresa)
        Certificados::ResolverParaEmpresa.call(
          empresa_id: empresa.id,
          persona_autorizada_id: params[:persona_autorizada_id],
          user_id: params[:user_id]
        )
      end

      def documento_emitido_json(documento)
        {
          id: documento.id,
          folio: documento.folio,
          tipo_documento: documento.tipo_documento_codigo,
          rut_receptor: documento.rut_receptor,
          razon_social_receptor: documento.razon_social_receptor
        }
      end

      def enviar_al_sii_si_corresponde(resultado)
        return envio_sii_omitido unless enviar_sii?

        Dte::EnviadorSii.call(
          xml_firmado: resultado[:resultado_firma][:xml_firmado],
          empresa_id: resultado[:empresa].id,
          certificado: resultado[:certificado]
        )
      end

      def enviar_sii?
        valor = params[:enviar_sii]
        return false if valor.nil?

        ActiveModel::Type::Boolean.new.cast(valor)
      end

      def envio_sii_omitido
        { success: false, omitido: true, pendiente: false, error: nil, track_id: nil }
      end

      def resultado_envio_json(resultado_envio)
        if resultado_envio[:omitido]
          { enviado: false, omitido: true, pendiente: false, track_id: nil }
        elsif resultado_envio[:pendiente]
          { enviado: false, omitido: false, pendiente: true, error: resultado_envio[:error], track_id: nil }
        elsif resultado_envio[:success]
          { enviado: true, omitido: false, pendiente: false, track_id: resultado_envio[:track_id] }
        else
          { enviado: false, omitido: false, pendiente: false, error: resultado_envio[:error], track_id: nil }
        end
      end

      def mensaje_generar(resultado_envio)
        return 'DTE generado y enviado al SII correctamente' if resultado_envio[:success]
        return 'DTE generado correctamente (envío al SII pendiente de implementación)' if resultado_envio[:pendiente]

        'DTE generado y persistido correctamente'
      end

      def error_emision_json(error)
        {
          success: false,
          error: error.message,
          backtrace: Rails.env.development? ? error.backtrace.first(10) : nil
        }
      end

      def validar_params_preparar
        errores = []
        errores << 'empresa_id es requerido' unless params[:empresa_id].present?
        errores << 'tipo_documento es requerido' unless params[:tipo_documento].present?
        errores << 'receptor es requerido' unless params[:receptor].present?
        errores << 'items es requerido' unless params[:items].present?
        errores << 'items debe tener al menos un elemento' if params[:items].present? && params[:items].empty?

        # Validar que cada item tenga producto_id y cantidad
        if params[:items].present? && params[:items].any?
          params[:items].each_with_index do |item, index|
            producto_id = item[:producto_id] || item['producto_id']
            cantidad = item[:cantidad] || item['cantidad']
            errores << "items[#{index}]: producto_id es requerido" unless producto_id.present?
            errores << "items[#{index}]: cantidad es requerida" unless cantidad.present?
          end
        end

        errores
      end

      def preparar_items(items_params)
        # Convierte { producto_id, cantidad } del request en ítems listos para clasificar y XML
        items_params.map do |item|
          producto_id = (item[:producto_id] || item['producto_id']).to_i
          cantidad = (item[:cantidad] || item['cantidad']).to_f
          descuento_pct = (item[:descuento_pct] || item['descuento_pct'] || 0).to_f
          descuento = (item[:descuento] || item['descuento'] || 0).to_f

          # Obtener producto de la base de datos
          producto = Producto.includes(:impuestos).find(producto_id)

          # Afecto = tiene impuestos asociados en producto_impuestos (ej: IVA 19%)
          afecto = producto.producto_impuestos.any?

          # Obtener impuestos del producto
          impuestos = obtener_impuestos_producto(producto)

          # Calcular subtotal y neto
          subtotal = cantidad * producto.precio_unitario
          descuento_monto = descuento > 0 ? descuento : (subtotal * descuento_pct / 100)
          neto = (subtotal - descuento_monto).to_i

          {
            producto_id: producto_id,
            codigo: producto.codigo,
            glosa: producto.nombre,
            cantidad: cantidad,
            precio_unitario: producto.precio_unitario.to_f,
            descuento_pct: descuento_pct,
            descuento: descuento_monto,
            neto: neto,
            afecto: afecto,
            impuestos: impuestos
          }
        end
      end

      def obtener_impuestos_producto(producto)
        producto.impuestos.map do |impuesto|
          {
            codigo: impuesto.abreviacion,
            nombre: impuesto.nombre,
            tasa: impuesto.valor_vigente || 0
          }
        end
      end

      # Une datos de empresa/receptor con páginas ya clasificadas y con folio asignado.
      # Cada página queda con sus ítems filtrados y totales calculados independientemente.
      def construir_estructura_dte(empresa:, receptor:, tipo_documento:, items:, paginas:)
        fecha_emision = Time.current.in_time_zone(Rails.application.config.sii.timezone)

        {
          emisor: {
            rut: empresa.rut,
            razon_social: empresa.razon_social,
            giro: empresa.giro,
            direccion: empresa.direccion,
            telefono: empresa.telefono1,
            fecha_resolucion: empresa.fecha_resolucion,
            numero_resolucion: empresa.numero_resolucion
          },
          receptor: {
            rut: receptor[:rut] || receptor['rut'],
            razon_social: receptor[:razon_social] || receptor['razon_social'],
            giro: receptor[:giro] || receptor['giro'],
            direccion: receptor[:direccion] || receptor['direccion'],
            email: receptor[:email] || receptor['email']
          },
          documento: {
            tipo_dte: tipo_documento,
            fecha_emision: fecha_emision.strftime('%Y-%m-%d'),
            timestamp: fecha_emision.strftime('%Y-%m-%dT%H:%M:%S')
          },
          paginas: paginas.map do |pg|
            items_pagina = items.select { |i| i[:pagina] == pg[:pagina] }
            totales = calcular_totales(items_pagina)

            {
              numero: pg[:pagina],
              folio: pg[:folio],
              archivo_caf: pg[:archivo_caf],
              items: items_pagina,
              totales: totales
            }
          end
        }
      end

      # Acumula neto afecto/exento e impuestos por ítem; separa IVA del resto
      def calcular_totales(items)
        neto_afecto = 0
        neto_exento = 0
        impuestos_acumulados = {}

        items.each do |item|
          if item[:afecto]
            neto_afecto += item[:neto]

            # Acumular impuestos por tipo
            item[:impuestos].each do |imp|
              codigo = imp[:codigo]
              impuestos_acumulados[codigo] ||= { codigo: codigo, nombre: imp[:nombre], tasa: imp[:tasa], monto: 0 }
              impuestos_acumulados[codigo][:monto] += (item[:neto] * imp[:tasa] / 100.0).to_i
            end
          else
            neto_exento += item[:neto]
          end
        end

        # Calcular total de impuestos
        total_impuestos = impuestos_acumulados.values.sum { |imp| imp[:monto] }
        total = neto_afecto + neto_exento + total_impuestos

        # Obtener IVA específico si existe
        iva_info = impuestos_acumulados['IVA'] || { tasa: 0, monto: 0 }

        {
          neto_afecto: neto_afecto,
          neto_exento: neto_exento,
          tasa_iva: iva_info[:tasa],
          iva: iva_info[:monto],
          otros_impuestos: impuestos_acumulados.reject { |k, _| k == 'IVA' }.values,
          total_impuestos: total_impuestos,
          total: total
        }
      end

      # Limpia archivos temporales generados durante el proceso DTE
      def limpiar_archivos_temporales(*archivos)
        archivos.flatten.compact.each do |archivo|
          next unless archivo.is_a?(String) || archivo.is_a?(Pathname)
          
          path = archivo.to_s
          if File.exist?(path) && path.start_with?(Rails.root.join('tmp').to_s)
            File.delete(path)
            Rails.logger.debug "=== Archivo temporal eliminado: #{path} ==="
          end
        rescue StandardError => e
          Rails.logger.warn "=== Error eliminando archivo temporal #{path}: #{e.message} ==="
        end
      end

      # Limpia archivos temporales intermedios (excluye archivos firmados)
      def limpiar_archivos_temporales_antiguos(minutos = 60)
        tmp_dir = Rails.root.join('tmp')
        # Solo PDFs y XMLs intermedios (no los firmados)
        patrones = ['dte_*.pdf', 'test_clasificacion_*.pdf']
        tiempo_limite = Time.current - minutos.minutes
        
        patrones.each do |patron|
          Dir.glob(tmp_dir.join(patron)).each do |archivo|
            if File.mtime(archivo) < tiempo_limite
              File.delete(archivo)
              Rails.logger.debug "=== Archivo temporal eliminado: #{archivo} ==="
            end
          rescue StandardError => e
            Rails.logger.warn "=== Error eliminando archivo temporal #{archivo}: #{e.message} ==="
          end
        end

        # XML intermedios (excluir dte_firmado_*)
        Dir.glob(tmp_dir.join('dte_*.xml')).each do |archivo|
          next if File.basename(archivo).start_with?('dte_firmado_')
          
          if File.mtime(archivo) < tiempo_limite
            File.delete(archivo)
            Rails.logger.debug "=== Archivo XML temporal eliminado: #{archivo} ==="
          end
        rescue StandardError => e
          Rails.logger.warn "=== Error eliminando archivo XML temporal #{archivo}: #{e.message} ==="
        end
      end

      # Limpia archivos firmados antiguos (llamar manualmente o por job)
      def limpiar_archivos_firmados_antiguos(dias = 7)
        tmp_dir = Rails.root.join('tmp')
        tiempo_limite = Time.current - dias.days
        
        Dir.glob(tmp_dir.join('dte_firmado_*.xml')).each do |archivo|
          if File.mtime(archivo) < tiempo_limite
            File.delete(archivo)
            Rails.logger.info "=== Archivo firmado antiguo eliminado: #{archivo} ==="
          end
        rescue StandardError => e
          Rails.logger.warn "=== Error eliminando archivo firmado #{archivo}: #{e.message} ==="
        end
      end
    end
  end
end

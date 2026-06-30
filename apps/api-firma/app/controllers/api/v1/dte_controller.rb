# frozen_string_literal: true

module Api
  module V1
    class DteController < BaseController
      include DteAuditable
      include DteDescuentosRecargosParams
      include DteReferenciasParams

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

        errores = validar_params_preparar
        if errores.any?
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_PREPARAR,
            mensaje: errores.join(', '),
            metadata: { fase: 'validacion' }
          )
          return render json: { success: false, errors: errores }, status: :unprocessable_entity
        end

        empresa = Empresa.find_by(id: params[:empresa_id])
        unless empresa
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_PREPARAR,
            mensaje: 'Empresa no encontrada',
            metadata: { fase: 'empresa', empresa_id: params[:empresa_id] }
          )
          return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found
        end

        @empresa_auditoria_dte = empresa
        items_array = preparar_items(params[:items], empresa_id: empresa.id)

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
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_PREPARAR,
            empresa: empresa,
            mensaje: resultado_folios[:error],
            metadata: metadata_dte_emision(empresa: empresa, fase: 'asignacion_folios'),
            codigo_error: 'asignacion_folios'
          )
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

        auditar_dte(
          accion: Auditoria::Acciones::DTE_PREPARAR,
          empresa: empresa,
          recurso_label: etiqueta_recurso_dte(folios: resultado_folios[:folios_usados]),
          metadata: metadata_dte_emision(
            empresa: empresa,
            folios: resultado_folios[:folios_usados],
            total_items: items_array.count,
            total_paginas: resultado_folios[:paginas].count
          )
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

      rescue Dte::DescuentosRecargos::Error => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_PREPARAR,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'calculo_totales' }
        )
        render json: error_calculo_descuentos_recargos(e), status: :unprocessable_entity
      rescue StandardError => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_PREPARAR,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'excepcion' }
        )
        render json: {
          success: false,
          error: e.message,
          backtrace: Rails.env.development? ? e.backtrace.first(10) : nil
        }, status: :internal_server_error
      ensure
        limpiar_archivos_temporales([archivo_temp]) if archivo_temp
      end

      # POST /api/v1/dte/calcular_totales
      # Preview de totales con descuentos/recargos globales (sin folios, XML ni firma).
      # Mismo body que /preparar, más descuentos_recargos_globales opcional.
      #
      # Requiere JWT y vínculo con la empresa.
      #
      def calcular_totales
        errores = validar_params_preparar
        if errores.any?
          return render json: { success: false, errors: errores }, status: :unprocessable_entity
        end

        authorize_empresa!(params[:empresa_id])
        return if performed?

        empresa = Empresa.find_by(id: params[:empresa_id])
        unless empresa
          return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found
        end

        items_preparados = preparar_items(params[:items], empresa_id: empresa.id)
        resultado = calcular_documento_con_globales(items_preparados: items_preparados)

        unless resultado[:success]
          mensajes = Array(resultado[:errors] || resultado[:error]).flatten.compact
          return render json: {
            success: false,
            errors: mensajes.presence || ['No se pudo calcular totales']
          }, status: :unprocessable_entity
        end

        render json: {
          success: true,
          data: payload_calcular_totales_dte(resultado)
        }, status: :ok
      rescue ActiveRecord::RecordNotFound, StandardError => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
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

        errores = validar_params_preparar
        if errores.any?
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_GENERAR_XML,
            mensaje: errores.join(', '),
            metadata: { fase: 'validacion' }
          )
          return render json: { success: false, errors: errores }, status: :unprocessable_entity
        end

        empresa = Empresa.includes(:acteco_empresas, actecos: []).find_by(id: params[:empresa_id])
        unless empresa
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_GENERAR_XML,
            mensaje: 'Empresa no encontrada',
            metadata: { fase: 'empresa', empresa_id: params[:empresa_id] }
          )
          return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found
        end

        @empresa_auditoria_dte = empresa
        items_array = preparar_items(params[:items], empresa_id: empresa.id)

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
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_GENERAR_XML,
            empresa: empresa,
            mensaje: resultado_folios[:error],
            metadata: metadata_dte_emision(empresa: empresa, fase: 'asignacion_folios'),
            codigo_error: 'asignacion_folios'
          )
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
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_GENERAR_XML,
            empresa: empresa,
            mensaje: resultado_xml[:error],
            metadata: metadata_dte_emision(
              empresa: empresa,
              folios: resultado_folios[:folios_usados],
              fase: 'generacion_xml'
            ),
            codigo_error: 'generacion_xml'
          )
          return render json: {
            success: false,
            error: resultado_xml[:error],
            fase: 'generacion_xml'
          }, status: :internal_server_error
        end

        # Limpiar archivos antiguos (más de 60 minutos)
        limpiar_archivos_temporales_antiguos(60)

        auditar_dte(
          accion: Auditoria::Acciones::DTE_GENERAR_XML,
          empresa: empresa,
          recurso_label: etiqueta_recurso_dte(folios: resultado_folios[:folios_usados]),
          metadata: metadata_dte_emision(
            empresa: empresa,
            folios: resultado_folios[:folios_usados],
            total_items: items_array.count,
            total_paginas: resultado_folios[:paginas].count,
            total_documentos: resultado_xml[:total_documentos]
          )
        )

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

      rescue Dte::DescuentosRecargos::Error => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_GENERAR_XML,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'calculo_totales' }
        )
        render json: error_calculo_descuentos_recargos(e), status: :unprocessable_entity
      rescue StandardError => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_GENERAR_XML,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'excepcion' }
        )
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
        @accion_auditoria_dte = Auditoria::Acciones::DTE_FIRMAR

        resultado = emitir_dte_firmado
        return render_resultado_emision(resultado) unless resultado[:success]

        auditar_dte(
          accion: Auditoria::Acciones::DTE_FIRMAR,
          empresa: resultado[:empresa],
          recurso_label: etiqueta_recurso_dte(folios: resultado[:resultado_folios][:folios_usados]),
          metadata: metadata_dte_emision_completa(resultado)
        )

        limpiar_archivos_temporales_antiguos(60)

        render json: respuesta_firmar_xml(resultado), status: :ok
      rescue StandardError => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_FIRMAR,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'excepcion' }
        )
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
        @accion_auditoria_dte = Auditoria::Acciones::DTE_EMITIR

        errores = validar_params_preparar
        if errores.any?
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_EMITIR,
            mensaje: errores.join(', '),
            metadata: { fase: 'validacion' }
          )
          return render json: { success: false, errors: errores }, status: :unprocessable_entity
        end

        authorize_empresa!(params[:empresa_id])
        return if performed?

        resultado = emitir_dte_firmado
        return render_resultado_emision(resultado) unless resultado[:success]

        resultado_persistencia = nil
        resultado_archivo = nil
        error_post_firma = nil

        ActiveRecord::Base.transaction do
          resultado_persistencia = Dte::PersistidorDocumento.call(
            empresa: resultado[:empresa],
            usuario: current_user,
            tipo_documento: params[:tipo_documento].to_i,
            receptor: params[:receptor],
            paginas: resultado[:resultado_folios][:paginas],
            items: resultado[:items_clasificados],
            movimientos_globales_raw: descuentos_recargos_globales_raw,
            referencias: referencias_normalizadas
          )

          unless resultado_persistencia[:success]
            error_post_firma = resultado_persistencia[:error]
            raise ActiveRecord::Rollback
          end

          resultado_archivo = Dte::ArchivadorXml.call(
            empresa: resultado[:empresa],
            usuario: current_user,
            tipo_documento: params[:tipo_documento].to_i,
            xml_firmado: resultado[:resultado_firma][:xml_firmado],
            documentos: resultado_persistencia[:documentos],
            folios: resultado[:resultado_folios][:folios_usados]
          )

          unless resultado_archivo[:success]
            error_post_firma = resultado_archivo[:error]
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
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_EMITIR,
            empresa: resultado[:empresa],
            mensaje: error_post_firma,
            metadata: metadata_dte_emision_completa(resultado).merge(fase: 'persistencia_documento'),
            codigo_error: 'persistencia_documento'
          )
          return render json: {
            success: false,
            error: error_post_firma,
            fase: 'persistencia_documento',
            advertencia: 'El DTE fue firmado pero no se pudo persistir en BD ni marcar folios'
          }, status: :internal_server_error
        end

        resultado_pdfs = Dte::Pdf::GeneradorLote.call(documentos: resultado_persistencia[:documentos])

        if resultado_pdfs[:fallos].any?
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_EMITIR,
            empresa: resultado[:empresa],
            mensaje: 'Emisión exitosa pero falló la generación de uno o más PDF',
            metadata: metadata_dte_emision_completa(resultado, resultado_persistencia: resultado_persistencia)
              .merge(fase: 'generacion_pdf', pdf_fallos: resultado_pdfs[:fallos]),
            codigo_error: 'generacion_pdf'
          )
        end

        resultado_envio = enviar_al_sii_si_corresponde(resultado)

        limpiar_archivos_temporales_antiguos(60)

        doc_ids = resultado_persistencia[:documentos].map(&:id)
        auditar_dte(
          accion: Auditoria::Acciones::DTE_EMITIR,
          empresa: resultado[:empresa],
          recurso: { tipo: 'DocumentoEmitido', id: doc_ids.first, label: etiqueta_recurso_dte(folios: resultado[:resultado_folios][:folios_usados]) },
          metadata: metadata_dte_emision_completa(
            resultado,
            resultado_persistencia: resultado_persistencia,
            resultado_envio: resultado_envio,
            resultado_pdfs: resultado_pdfs
          ).merge(referencias_count: referencias_normalizadas.size)
        )

        render json: respuesta_generar(resultado, resultado_persistencia, resultado_archivo, resultado_envio, resultado_pdfs),
               status: :ok
      rescue StandardError => e
        auditar_dte_fallo(
          accion: Auditoria::Acciones::DTE_EMITIR,
          empresa: empresa_auditoria_dte,
          mensaje: e.message,
          metadata: { fase: 'excepcion' }
        )
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
        unless empresa
          return fallo_emision('Empresa no encontrada', fase: 'empresa', status: :not_found)
        end

        @empresa_auditoria_dte = empresa

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

        items_array = preparar_items(params[:items], empresa_id: empresa.id)

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

        begin
          estructura_dte = construir_estructura_dte(
            empresa: empresa,
            receptor: params[:receptor],
            tipo_documento: params[:tipo_documento].to_i,
            items: resultado_clasificacion[:items],
            paginas: resultado_folios[:paginas]
          )
        rescue Dte::DescuentosRecargos::Error => e
          return fallo_emision(
            e.message,
            fase: 'calculo_totales',
            status: :unprocessable_entity,
            errors: [e.message]
          )
        end

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
        accion = @accion_auditoria_dte || Auditoria::Acciones::DTE_EMITIR
        mensaje = error || errors&.join(', ')

        auditar_dte_fallo(
          accion: accion,
          empresa: empresa_auditoria_dte,
          mensaje: mensaje,
          metadata: metadata_dte_emision(empresa: empresa_auditoria_dte, fase: fase),
          codigo_error: fase
        )

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

      def respuesta_generar(resultado, resultado_persistencia, resultado_archivo, resultado_envio, resultado_pdfs = nil)
        dte_envio = resultado_archivo[:dte_envio]
        documentos = DocumentoEmitido.where(id: resultado_persistencia[:documentos].map(&:id))

        respuesta = {
          success: true,
          message: mensaje_generar(resultado_envio),
          data: {
            archivo_firmado: resultado[:archivo_firmado],
            dte_envio_id: dte_envio.id,
            xml_archivado: dte_envio.xml_firmado.attached?,
            total_documentos: resultado[:resultado_xml][:total_documentos],
            folios_usados: resultado[:resultado_folios][:folios_usados],
            documentos_emitidos: documentos.map { |doc| documento_emitido_json(doc) },
            envio_sii: resultado_envio_json(resultado_envio)
          },
          xml: resultado[:resultado_firma][:xml_firmado],
          resumen: resumen_emision(resultado)
        }

        if resultado_pdfs&.dig(:fallos)&.any?
          respuesta[:advertencia] = 'El DTE se emitió correctamente pero no se pudo generar el PDF de uno o más documentos'
          respuesta[:data][:pdf_fallos] = resultado_pdfs[:fallos]
        end

        respuesta
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
          razon_social_receptor: documento.razon_social_receptor,
          dte_envio_id: documento.dte_envio_id,
          pdf_disponible: documento.pdf.attached?
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

        errores.concat(errores_estructura_descuentos_recargos_globales)
        errores.concat(errores_referencias_dte)

        errores
      end

      def preparar_items(items_params, empresa_id:)
        # Convierte { producto_id, cantidad } del request en ítems listos para clasificar y XML
        items_params.map do |item|
          producto_id = (item[:producto_id] || item['producto_id']).to_i
          cantidad = (item[:cantidad] || item['cantidad']).to_f
          descuento_pct = (item[:descuento_pct] || item['descuento_pct'] || 0).to_f
          descuento = (item[:descuento] || item['descuento'] || 0).to_f
          recargo_pct = (item[:recargo_pct] || item['recargo_pct'] || 0).to_f
          recargo = (item[:recargo] || item['recargo'] || 0).to_f

          producto = Producto.includes(:impuestos, :producto_impuestos)
                             .find_by(id: producto_id, empresa_id: empresa_id)

          unless producto
            raise ActiveRecord::RecordNotFound, "Producto #{producto_id} no encontrado para la empresa"
          end

          unless producto.activo?
            raise StandardError, "El producto #{producto.codigo} está inactivo"
          end

          # Clasificación SII del ítem (afecto / exento / no facturable)
          impuestos = obtener_impuestos_producto(producto)
          clasificacion = producto.clasificacion
          ambito_monto = clasificacion.ambito_monto
          afecto = clasificacion.afecto?

          linea = Dte::DescuentosRecargos::LineaCalculada.from_item(
            cantidad: cantidad,
            precio_unitario: producto.precio_unitario.to_f,
            descuento_pct: descuento_pct,
            descuento: descuento,
            recargo_pct: recargo_pct,
            recargo: recargo,
            ambito_monto: ambito_monto,
            afecto: afecto
          )

          {
            producto_id: producto_id,
            codigo: producto.codigo,
            glosa: producto.nombre,
            cantidad: cantidad,
            precio_unitario: producto.precio_unitario.to_f,
            descuento_pct: descuento_pct,
            descuento: linea.descuento_linea,
            recargo_pct: recargo_pct,
            recargo: linea.recargo_linea,
            neto: linea.monto_neto,
            ambito_monto: ambito_monto,
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
        referencias = referencias_normalizadas

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
          referencias: referencias,
          paginas: paginas.map do |pg|
            items_pagina = items.select { |i| i[:pagina] == pg[:pagina] }
            resultado_pagina = calcular_pagina_dte(items_pagina: items_pagina)

            unless resultado_pagina[:success]
              mensaje = Array(resultado_pagina[:errors] || resultado_pagina[:error]).join('; ')
              raise Dte::DescuentosRecargos::Error, mensaje.presence || 'Error calculando totales del documento'
            end

            {
              numero: pg[:pagina],
              folio: pg[:folio],
              archivo_caf: pg[:archivo_caf],
              items: items_pagina,
              totales: resultado_pagina[:totales],
              descuentos_recargos_globales: resultado_pagina[:descuentos_recargos_globales],
              referencias: referencias
            }
          end
        }
      end

      def error_calculo_descuentos_recargos(error)
        {
          success: false,
          errors: [error.message],
          fase: 'calculo_totales'
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

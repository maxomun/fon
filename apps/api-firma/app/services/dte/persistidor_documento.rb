# frozen_string_literal: true

module Dte
  # Persiste los DTE emitidos en documento_emitidos y venta_detalles.
  # Crea un registro por cada página/folio del envío.
  class PersistidorDocumento
    def self.call(**params)
      new(**params).call
    end

    def initialize(empresa:, usuario:, tipo_documento:, receptor:, paginas:, items:, movimientos_globales_raw: nil,
                   referencias: nil)
      @empresa = empresa
      @usuario = usuario
      @tipo_documento = tipo_documento
      @receptor = receptor
      @paginas = paginas
      @items = items
      @movimientos_globales_raw = movimientos_globales_raw
      @referencias = referencias || []
    end

    def call
      tipo_habilitado = obtener_tipo_habilitado

      documentos = paginas.map do |pagina|
        persistir_pagina(tipo_habilitado, pagina)
      end

      { success: true, documentos: documentos }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, Dte::DescuentosRecargos::Error => e
      { success: false, error: e.message }
    end

    private

    attr_reader :empresa, :usuario, :tipo_documento, :receptor, :paginas, :items, :movimientos_globales_raw,
                :referencias

    def obtener_tipo_habilitado
      tipo_doc = TipoDocumento.find_by!(codigo: tipo_documento.to_s)
      TipoHabilitado.find_by!(empresa_id: empresa.id, tipo_documento_id: tipo_doc.id)
    end

    def persistir_pagina(tipo_habilitado, pagina)
      items_pagina = items.select { |item| item[:pagina] == pagina[:pagina] }
      receptor_data = normalizar_receptor

      documento = DocumentoEmitido.create!(
        empresa_id: empresa.id,
        folio: pagina[:folio],
        dte: true,
        manual: false,
        tipo_habilitado_id: tipo_habilitado.id,
        rut_emisor: empresa.rut,
        razon_social_emisor: empresa.razon_social,
        giro_emisor: empresa.giro,
        direccion_emisor: empresa.direccion,
        rut_receptor: receptor_data[:rut],
        razon_social_receptor: receptor_data[:razon_social],
        giro_receptor: receptor_data[:giro],
        direccion_receptor: receptor_data[:direccion],
        ingreso_integrado: false,
        ingreso_autonomo: true,
        referencia_id: 0,
        usuario_id: usuario.id
      )

      documento.update!(referencia_id: documento.id)

      items_pagina.each do |item|
        ambito_monto = item[:ambito_monto] || (
          item[:afecto] ? Dte::DescuentosRecargos::Constants::APLICA_SOBRE_AFECTO : Dte::DescuentosRecargos::Constants::APLICA_SOBRE_EXENTO
        )

        VentaDetalle.create!(
          documento_emitido_id: documento.id,
          item: item[:glosa],
          cantidad: item[:cantidad],
          precio_unitario: item[:precio_unitario],
          descuento: item[:descuento_pct] || 0,
          afecto: ambito_monto == Dte::DescuentosRecargos::Constants::APLICA_SOBRE_AFECTO,
          ambito_monto: ambito_monto,
          impuesto: tasa_impuesto_item(item),
          producto_id: item[:producto_id]
        )
      end

      persistir_descuentos_recargos_globales(documento, items_pagina, pagina)
      persistir_referencias(documento, pagina)

      documento
    end

    def persistir_descuentos_recargos_globales(documento, items_pagina, pagina)
      movimientos = pagina[:descuentos_recargos_globales]

      if movimientos.nil?
        resultado = Dte::DescuentosRecargos::IntegradorPagina.call(
          items_pagina: items_pagina,
          movimientos_globales_raw: movimientos_globales_raw
        )
        unless resultado[:success]
          errores = Array(resultado[:errors] || resultado[:error]).join('; ')
          raise Dte::DescuentosRecargos::Error, errores.presence || 'Error calculando movimientos globales'
        end

        movimientos = resultado[:descuentos_recargos_globales]
      end

      Array(movimientos).each do |movimiento|
        DocumentoDescuentoRecargoGlobal.crear_desde_hash!(
          documento_emitido: documento,
          movimiento: movimiento
        )
      end
    end

    def persistir_referencias(documento, pagina)
      refs = pagina[:referencias].nil? ? referencias : pagina[:referencias]

      Array(refs).each do |referencia|
        DocumentoEmitidoReferencia.crear_desde_hash!(
          documento_emitido: documento,
          referencia: referencia
        )
      end
    end

    def normalizar_receptor
      {
        rut: valor_receptor(:rut),
        razon_social: valor_receptor(:razon_social),
        giro: valor_receptor(:giro).presence || 'Sin giro',
        direccion: valor_receptor(:direccion).presence || 'Sin dirección'
      }
    end

    def valor_receptor(campo)
      receptor[campo] || receptor[campo.to_s] || ''
    end

    def tasa_impuesto_item(item)
      iva = item[:impuestos]&.find { |imp| imp[:codigo] == 'IVA' }
      iva ? iva[:tasa].to_f : 0
    end
  end
end

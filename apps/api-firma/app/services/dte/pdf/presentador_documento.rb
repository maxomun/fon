# frozen_string_literal: true

module Dte
  module Pdf
    # Arma el view-model para la plantilla HTML del PDF (sin recalcular totales del documento).
    class PresentadorDocumento
      def self.call(documento:)
        new(documento: documento).call
      end

      def initialize(documento:)
        @documento = documento
      end

      def call
        totales = totales_documento
        raise ArgumentError, 'No se pudieron obtener totales del documento' unless totales

        timbre = timbre_payload

        {
          tipo_dte: documento.tipo_documento_codigo,
          tipo_dte_nombre: documento.tipo_habilitado.tipo_documento.nombre,
          folio: documento.folio,
          fecha_emision: totales[:fecha_emision] || fecha_emision_fallback,
          sucursal: '',
          emisor: emisor_payload,
          receptor: receptor_payload,
          lineas: lineas_payload,
          globales: globales_payload,
          referencias: [],
          totales: {
            neto_afecto: totales[:neto_afecto],
            neto_exento: totales[:neto_exento],
            iva: totales[:iva],
            total: totales[:total]
          },
          ted_placeholder: timbre[:placeholder],
          ted_imagen_data_uri: timbre[:data_uri],
          logo_data_uri: logo_data_uri,
          resolucion_timbre: documento.empresa.resolucion_timbre
        }
      end

      private

      attr_reader :documento

      def emisor_payload
        {
          razon_social: documento.razon_social_emisor,
          rut: Formateador.rut(documento.rut_emisor),
          giro: documento.giro_emisor,
          direccion: documento.direccion_emisor,
          comuna: '',
          ciudad: ''
        }
      end

      def receptor_payload
        {
          razon_social: documento.razon_social_receptor,
          rut: Formateador.rut(documento.rut_receptor),
          giro: documento.giro_receptor,
          direccion: documento.direccion_receptor,
          comuna: '',
          ciudad: ''
        }
      end

      def lineas_payload
        documento.venta_detalles.sort_by(&:id).map do |linea|
          {
            codigo: linea.producto&.codigo.to_s.presence || '—',
            descripcion: linea.item,
            cantidad: linea.cantidad.to_f,
            unidad: 'UN',
            precio_unitario: linea.precio_unitario.to_f,
            descuento_pct: linea.descuento.to_f,
            recargo: 0,
            total: linea.subtotal_con_descuento.to_i
          }
        end
      end

      def globales_payload
        documento.documento_descuentos_recargos_globales.ordenados.map do |movimiento|
          {
            tipo: movimiento.tipo_movimiento == 'D' ? 'Descuento' : 'Recargo',
            glosa: movimiento.glosa,
            valor: etiqueta_valor(movimiento),
            monto: movimiento.monto_calculado,
            aplica_sobre: movimiento.aplica_sobre
          }
        end
      end

      def etiqueta_valor(movimiento)
        if movimiento.tipo_valor == 'PORCENTAJE'
          "#{Formateador.porcentaje(movimiento.valor)}%"
        else
          Formateador.moneda(movimiento.valor)
        end
      end

      def totales_documento
        xml = documento.dte_envio&.xml_firmado
        if xml&.attached?
          contenido = xml.download
          return LectorTotalesXml.call(xml_string: contenido, folio: documento.folio)
        end

        totales_desde_lineas
      end

      def totales_desde_lineas
        return nil if documento.documento_descuentos_recargos_globales.exists?

        neto_afecto = 0
        neto_exento = 0
        iva = 0

        documento.venta_detalles.each do |linea|
          if linea.afecto
            neto_afecto += linea.subtotal_con_descuento.to_i
            iva += linea.monto_impuesto.to_i
          else
            neto_exento += linea.subtotal_con_descuento.to_i
          end
        end

        {
          neto_afecto: neto_afecto,
          neto_exento: neto_exento,
          iva: iva,
          total: neto_afecto + neto_exento + iva,
          fecha_emision: fecha_emision_fallback
        }
      end

      def fecha_emision_fallback
        documento.dte_envio&.created_at&.strftime('%Y-%m-%d')
      end

      def timbre_payload
        xml = documento.dte_envio&.xml_firmado
        return placeholder_timbre unless xml&.attached?

        ted_node = LectorTedXml.call(xml_string: xml.download, folio: documento.folio)
        return placeholder_timbre unless ted_node

        ted_string = SerializadorTed.call(ted_node: ted_node)
        return placeholder_timbre if ted_string.blank?

        png_bytes = GeneradorPdf417.call(ted_string: ted_string)
        return placeholder_timbre unless png_bytes

        {
          placeholder: false,
          data_uri: "data:image/png;base64,#{Base64.strict_encode64(png_bytes)}"
        }
      end

      def placeholder_timbre
        { placeholder: true, data_uri: nil }
      end

      def logo_data_uri
        logo = documento.empresa.logo
        return nil unless logo.attached?

        blob = logo.blob
        "data:#{blob.content_type};base64,#{Base64.strict_encode64(blob.download)}"
      end
    end
  end
end

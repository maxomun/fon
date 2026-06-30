# frozen_string_literal: true

require 'date'

module Dte
  module Referencias
    # Resuelve y valida documento_emitido_origen_id contra DTE emitidos de la empresa.
    class DocumentoOrigen
      def self.fecha_emision(documento)
        new(documento: documento).fecha_emision
      end

      def self.validar_vinculo(referencia:, empresa_id:, prefijo:)
        new.validar_vinculo(referencia: referencia, empresa_id: empresa_id, prefijo: prefijo)
      end

      def initialize(documento: nil)
        @documento = documento
      end

      def fecha_emision
        return nil unless documento

        xml = documento.dte_envio&.xml_firmado
        if xml&.attached?
          totales = Dte::Pdf::LectorTotalesXml.call(
            xml_string: xml.download,
            folio: documento.folio
          )
          fecha = totales&.dig(:fecha_emision)
          return Date.iso8601(fecha) if fecha && !fecha.to_s.empty?
        end

        documento.dte_envio&.created_at&.to_date
      end

      def validar_vinculo(referencia:, empresa_id:, prefijo:)
        origen_id = referencia[:documento_emitido_origen_id]
        return [] if origen_id.nil?

        documento = DocumentoEmitido
                      .includes(tipo_habilitado: :tipo_documento, dte_envio: { xml_firmado_attachment: :blob })
                      .find_by(id: origen_id, empresa_id: empresa_id)

        unless documento&.dte? && !documento.dte_envio_id.nil?
          return ["#{prefijo}: documento_emitido_origen_id no corresponde a un DTE emitido de la empresa"]
        end

        tipo_catalogo = TipoReferenciaDocumento.activos.find_by(codigo_sii: referencia[:tipo_documento_referencia])
        unless tipo_catalogo&.categoria == 'DTE'
          return ["#{prefijo}: documento_emitido_origen_id solo aplica a tipos DTE referenciables"]
        end

        errores = []
        if documento.tipo_documento_codigo != referencia[:tipo_documento_referencia].to_s
          errores << "#{prefijo}: el documento origen no coincide con tipo_documento_referencia"
        end

        if documento.folio.to_s != referencia[:folio_referencia].to_s.strip
          errores << "#{prefijo}: folio_referencia no coincide con el documento origen seleccionado"
        end

        fecha_origen = self.class.fecha_emision(documento)
        if fecha_origen
          fecha_ref = Date.iso8601(referencia[:fecha_referencia].to_s)
          if fecha_ref != fecha_origen
            errores << "#{prefijo}: fecha_referencia no coincide con el documento origen seleccionado"
          end
        end

        errores
      rescue ArgumentError
        ["#{prefijo}: fecha_referencia debe tener formato YYYY-MM-DD"]
      end

      private

      attr_reader :documento
    end
  end
end

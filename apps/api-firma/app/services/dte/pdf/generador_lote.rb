# frozen_string_literal: true

module Dte
  module Pdf
    # Genera el PDF de cada documento emitido (uno por folio).
    # Los fallos se reportan por documento sin interrumpir el resto del lote.
    class GeneradorLote
      INCLUDES = [
        :empresa,
        { tipo_habilitado: :tipo_documento },
        { venta_detalles: :producto },
        :documento_descuentos_recargos_globales,
        { documento_emitido_referencias: :tipo_referencia_documento },
        { dte_envio: { xml_firmado_attachment: :blob } }
      ].freeze

      def self.call(documentos:, force: false)
        new(documentos: documentos, force: force).call
      end

      def initialize(documentos:, force: false)
        @documentos = documentos
        @force = force
      end

      def call
        generados = 0
        fallos = []

        documentos.each do |documento|
          doc = DocumentoEmitido.includes(INCLUDES).find(documento.id)
          resultado = Generador.call(documento: doc, force: force)

          if resultado[:success]
            generados += 1 if resultado[:generado]
          else
            fallos << {
              documento_id: doc.id,
              folio: doc.folio,
              error: resultado[:error],
              code: resultado[:code]
            }
            Rails.logger.warn(
              "[Dte::Pdf::GeneradorLote] PDF no generado documento=#{doc.id} folio=#{doc.folio}: #{resultado[:error]}"
            )
          end
        end

        { success: fallos.empty?, generados: generados, fallos: fallos }
      end

      private

      attr_reader :documentos, :force
    end
  end
end

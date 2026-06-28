# frozen_string_literal: true

require 'stringio'

module Dte
  module Pdf
    class Generador
      ATTACHMENT_NAME = 'pdf'

      def self.call(documento:, force: false)
        new(documento: documento, force: force).call
      end

      def initialize(documento:, force: false)
        @documento = documento
        @force = force
      end

      def call
        if documento.pdf.attached? && !force
          return { success: true, generado: false, documento: documento }
        end

        presentacion = PresentadorDocumento.call(documento: documento)
        html = render_html(presentacion)
        pdf_bytes = convertir_a_pdf(html)

        ActiveStorage::EliminadorSinPurge.call(record: documento, name: :pdf) if documento.pdf.attached?
        documento.pdf.attach(
          io: StringIO.new(pdf_bytes),
          filename: NombreArchivo.for(documento: documento),
          content_type: 'application/pdf'
        )

        unless documento.pdf.attached?
          return { success: false, error: 'No se pudo adjuntar el PDF', code: 'PDF_ATTACH_FAILED' }
        end

        { success: true, generado: true, documento: documento }
      rescue ArgumentError => e
        { success: false, error: e.message, code: 'PDF_INVALID_DATA' }
      rescue Grover::JavaScript::Error, Grover::DependencyError => e
        { success: false, error: "Error al renderizar PDF: #{e.message}", code: 'PDF_RENDER_FAILED' }
      rescue StandardError => e
        Rails.logger.error("Dte::Pdf::Generador error: #{e.message}")
        { success: false, error: e.message, code: 'PDF_ERROR' }
      end

      private

      attr_reader :documento, :force

      def render_html(presentacion)
        ActionController::Base.render(
          template: 'dte/pdf/documento',
          layout: false,
          locals: { presentacion: presentacion }
        )
      end

      def convertir_a_pdf(html)
        Grover.new(html, **opciones_grover).to_pdf
      end

      def opciones_grover
        {
          format: 'A4',
          margin: {
            top: '12mm',
            bottom: '12mm',
            left: '10mm',
            right: '10mm'
          },
          print_background: true,
          prefer_css_page_size: true
        }
      end
    end
  end
end

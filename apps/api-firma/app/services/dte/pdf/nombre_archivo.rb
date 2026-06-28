# frozen_string_literal: true

module Dte
  module Pdf
    class NombreArchivo
      def self.for(documento:)
        new(documento: documento).to_s
      end

      def initialize(documento:)
        @documento = documento
      end

      def to_s
        rut = documento.rut_emisor.to_s.gsub(/[.\s]/, '')
        fecha = (documento.dte_envio&.created_at || Time.current).strftime('%Y%m%d')
        "dte_#{documento.tipo_documento_codigo}_folio_#{documento.folio}_#{rut}_#{fecha}.pdf"
      end

      private

      attr_reader :documento
    end
  end
end

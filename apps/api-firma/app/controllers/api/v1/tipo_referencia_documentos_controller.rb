# frozen_string_literal: true

module Api
  module V1
    class TipoReferenciaDocumentosController < BaseController
      include TipoReferenciaDocumentoSerializable

      # GET /api/v1/tipo_referencia_documentos?q=&categoria=
      def index
        tipos = TipoReferenciaDocumento.activos.ordenados

        if params[:categoria].present?
          tipos = tipos.where(categoria: params[:categoria].to_s.strip)
        end

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          tipos = tipos.where('codigo_sii ILIKE :q OR nombre ILIKE :q', q: query)
        end

        render_success(data: tipos.map { |tipo| tipo_referencia_documento_payload(tipo) })
      end
    end
  end
end

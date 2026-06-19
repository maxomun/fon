# frozen_string_literal: true

module Api
  module V1
    class TipoDocumentosController < BaseController
      include TipoDocumentoSerializable

      before_action :require_administrador_fon!

      # GET /api/v1/tipo_documentos?q=&exclude_empresa_id=
      def index
        tipos = TipoDocumento.habilitables.order(:codigo)

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          tipos = tipos.where('codigo ILIKE :q OR nombre ILIKE :q', q: query)
        end

        if params[:exclude_empresa_id].present?
          habilitados_ids = TipoHabilitado
            .where(empresa_id: params[:exclude_empresa_id])
            .select(:tipo_documento_id)
          tipos = tipos.where.not(id: habilitados_ids)
        end

        render_success(data: tipos.map { |tipo| tipo_documento_payload(tipo) })
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end
    end
  end
end

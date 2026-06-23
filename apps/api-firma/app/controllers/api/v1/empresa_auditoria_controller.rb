# frozen_string_literal: true

module Api
  module V1
    class EmpresaAuditoriaController < BaseController
      include EmpresaAuthorizable
      include AuditoriaQueryable

      before_action :authorize_acceso_auditoria_empresa!
      before_action :set_evento, only: [:show]

      # GET /api/v1/empresas/:empresa_id/auditoria
      def index
        listar_eventos_auditoria(AuditEvent.de_empresa(params[:empresa_id]))
      end

      # GET /api/v1/empresas/:empresa_id/auditoria/:id
      def show
        render_evento_auditoria(@evento)
      end

      private

      def authorize_acceso_auditoria_empresa!
        return if current_user.administrador_fon?

        authorize_admin_empresa!(params[:empresa_id])
      end

      def permitir_filtro_empresa_id?
        false
      end

      def set_evento
        @evento = AuditEvent.de_empresa(params[:empresa_id]).includes(:empresa).find(params[:id])
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class AuditoriaController < BaseController
      include EmpresaAuthorizable
      include AuditoriaQueryable

      before_action :require_administrador_fon!
      before_action :set_evento, only: [:show]

      # GET /api/v1/auditoria
      def index
        listar_eventos_auditoria(AuditEvent.all)
      end

      # GET /api/v1/auditoria/:id
      def show
        render_evento_auditoria(@evento)
      end

      private

      def set_evento
        @evento = AuditEvent.includes(:empresa).find(params[:id])
      end
    end
  end
end

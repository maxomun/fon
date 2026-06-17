# frozen_string_literal: true

module Api
  module V1
    class ActecosController < BaseController
      include ActecoSerializable

      before_action :require_administrador_fon!

      # GET /api/v1/actecos?q=&exclude_empresa_id=
      def index
        actecos = Acteco.includes(:grupo_acteco).where(disponible_internet: true).order(:codigo)

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          actecos = actecos.where('codigo ILIKE :q OR nombre ILIKE :q', q: query)
        end

        if params[:exclude_empresa_id].present?
          assigned_ids = ActecoEmpresa
            .where(empresa_id: params[:exclude_empresa_id])
            .select(:acteco_id)
          actecos = actecos.where.not(id: assigned_ids)
        end

        actecos = actecos.limit(50)

        render_success(data: actecos.map { |acteco| acteco_payload(acteco) })
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end
    end
  end
end

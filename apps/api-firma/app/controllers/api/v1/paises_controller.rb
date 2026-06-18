# frozen_string_literal: true

module Api
  module V1
    class PaisesController < BaseController
      include PaisSerializable

      before_action :require_administrador_fon!

      # GET /api/v1/paises
      def index
        paises = Pais.activos.order(:nombre)
        render_success(data: paises.map { |pais| pais_payload(pais) })
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end
    end
  end
end

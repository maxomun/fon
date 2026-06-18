# frozen_string_literal: true

module Api
  module V1
    class EmpresaPersonasAutorizadasController < BaseController
      include PersonaAutorizadaSerializable

      before_action :require_administrador_fon!
      before_action :set_empresa

      # GET /api/v1/empresas/:empresa_id/personas_autorizadas
      def index
        asignaciones = @empresa
          .empresa_personas_autorizadas
          .includes(:persona_autorizada)
          .joins(:persona_autorizada)
          .order('personas_autorizadas.orden', 'personas_autorizadas.id')

        render_success(
          data: asignaciones.map do |asignacion|
            persona_autorizada_asignada_payload(
              asignacion.persona_autorizada,
              asignacion: asignacion
            )
          end
        )
      end

      # POST /api/v1/empresas/:empresa_id/personas_autorizadas
      def create
        persona = PersonaAutorizada.find(asignacion_params[:persona_autorizada_id])
        asignacion = @empresa.empresa_personas_autorizadas.build(persona_autorizada: persona)

        if asignacion.save
          render_success(
            data: persona_autorizada_asignada_payload(persona, asignacion: asignacion),
            status: :created,
            message: 'Persona autorizada asignada a la empresa exitosamente'
          )
        else
          render_persona_validation_error(asignacion)
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/personas_autorizadas/:id
      def destroy
        asignacion = @empresa.empresa_personas_autorizadas.find_by!(persona_autorizada_id: params[:id])
        asignacion.destroy!
        render_success(message: 'Persona autorizada quitada de la empresa exitosamente')
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def asignacion_params
        params.require(:persona_autorizada).permit(:persona_autorizada_id)
      end
    end
  end
end

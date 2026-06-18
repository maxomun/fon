# frozen_string_literal: true

module Api
  module V1
    class PersonasAutorizadasController < BaseController
      include PersonaAutorizadaSerializable

      before_action :require_administrador_fon!
      before_action :set_persona_autorizada, only: [:show, :update, :destroy]

      # GET /api/v1/personas_autorizadas?q=
      def index
        personas = PersonaAutorizada.por_prioridad

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          personas = personas.where(
            'rut ILIKE :q OR nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q OR email ILIKE :q',
            q: query
          )
        end

        if params[:exclude_empresa_id].present?
          asignadas_ids = EmpresaPersonaAutorizada
            .where(empresa_id: params[:exclude_empresa_id])
            .select(:persona_autorizada_id)
          personas = personas.where.not(id: asignadas_ids)
        end

        personas = personas.limit(100)

        render_success(data: personas.map { |persona| persona_autorizada_payload(persona) })
      end

      # GET /api/v1/personas_autorizadas/:id
      def show
        render_success(data: persona_autorizada_payload(@persona_autorizada, include_empresas: true))
      end

      # POST /api/v1/personas_autorizadas
      def create
        persona = PersonaAutorizada.new(persona_autorizada_params)

        if persona.save
          render_success(
            data: persona_autorizada_payload(persona),
            status: :created,
            message: 'Persona autorizada creada exitosamente'
          )
        else
          render_persona_validation_error(persona)
        end
      end

      # PATCH/PUT /api/v1/personas_autorizadas/:id
      def update
        if @persona_autorizada.update(persona_autorizada_params)
          render_success(
            data: persona_autorizada_payload(@persona_autorizada, include_empresas: true),
            message: 'Persona autorizada actualizada exitosamente'
          )
        else
          render_persona_validation_error(@persona_autorizada)
        end
      end

      # DELETE /api/v1/personas_autorizadas/:id
      def destroy
        if @persona_autorizada.destroy
          render_success(message: 'Persona autorizada eliminada exitosamente')
        else
          render_error(
            'No se puede eliminar la persona autorizada',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED',
            errors: @persona_autorizada.errors.full_messages
          )
        end
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def set_persona_autorizada
        @persona_autorizada = PersonaAutorizada.find(params[:id])
      end

      def persona_autorizada_params
        permitted = params.require(:persona_autorizada).permit(
          :rut,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :email,
          :estado,
          :orden,
          :user_id
        )

        if action_name == 'create'
          permitted[:estado] = PersonaAutorizada::ESTADO_ACTIVO if permitted[:estado].blank?
          permitted[:orden] = 1 if permitted[:orden].blank?
        end

        permitted[:user_id] = nil if permitted.key?(:user_id) && permitted[:user_id].blank?
        permitted
      end
    end
  end
end

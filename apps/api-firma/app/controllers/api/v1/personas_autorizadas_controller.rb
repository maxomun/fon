# frozen_string_literal: true

module Api
  module V1
    class PersonasAutorizadasController < BaseController
      include PersonaAutorizadaSerializable
      include EmpresaAuthorizable

      before_action :require_administrador_fon!
      before_action :set_persona_autorizada, only: [:show, :update, :destroy, :reenviar_onboarding]

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
        resultado = PersonasAutorizadas::Crear.call(
          attributes: persona_autorizada_params_for_create,
          password: params.dig(:persona_autorizada, :password)
        )

        if resultado.success?
          render_success(
            data: persona_autorizada_payload(resultado.persona_autorizada),
            status: :created,
            message: mensaje_onboarding(
              onboarding_email_enviado: resultado.onboarding_email_enviado,
              accion: :creada
            )
          )
        else
          render_error(
            'Error al crear persona autorizada',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      # PATCH/PUT /api/v1/personas_autorizadas/:id
      def update
        @onboarding_email_enviado = false

        if @persona_autorizada.update(persona_autorizada_params_for_update)
          asegurar_usuario_vinculado!
          return if performed?

          render_success(
            data: persona_autorizada_payload(@persona_autorizada, include_empresas: true),
            message: mensaje_onboarding(
              onboarding_email_enviado: @onboarding_email_enviado,
              accion: :actualizada
            )
          )
        else
          render_persona_validation_error(@persona_autorizada)
        end
      end

      # POST /api/v1/personas_autorizadas/:id/reenviar_onboarding
      def reenviar_onboarding
        resultado = PersonasAutorizadas::ReenviarOnboarding.call(
          persona_autorizada: @persona_autorizada
        )

        if resultado.success?
          render_success(
            data: persona_autorizada_payload(@persona_autorizada),
            message: mensaje_reenvio_onboarding(paso: resultado.paso)
          )
        else
          render_error(
            'No se pudo reenviar el correo de enrolamiento',
            :unprocessable_entity,
            code: 'ONBOARDING_RESEND_FAILED',
            errors: resultado.errors
          )
        end
      end

      # DELETE /api/v1/personas_autorizadas/:id
      def destroy
        unless @persona_autorizada.puede_eliminarse?
          return render_error(
            'No se puede eliminar la persona autorizada porque tiene empresas o certificados asociados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED'
          )
        end

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

      def set_persona_autorizada
        @persona_autorizada = PersonaAutorizada.find(params[:id])
      end

      def persona_autorizada_params_for_create
        permitted = persona_autorizada_base_params
        permitted[:estado] = PersonaAutorizada::ESTADO_ACTIVO if permitted[:estado].blank?
        permitted[:orden] = 1 if permitted[:orden].blank?
        permitted
      end

      def persona_autorizada_params_for_update
        persona_autorizada_base_params
      end

      def persona_autorizada_base_params
        params.require(:persona_autorizada).permit(
          :rut,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :email,
          :estado,
          :orden
        )
      end

      def asegurar_usuario_vinculado!
        if @persona_autorizada.user.present?
          @persona_autorizada.sincronizar_nombre_a_usuario!
          return
        end

        resultado = PersonasAutorizadas::ProvisionarUsuario.call(
          persona_autorizada: @persona_autorizada,
          password: params.dig(:persona_autorizada, :password)
        )

        unless resultado.success?
          render_error(
            'Persona actualizada pero no se pudo provisionar el usuario',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
          return
        end

        envio = PersonasAutorizadas::EnviarVerificacionEmail.call(user: @persona_autorizada.user)
        @onboarding_email_enviado = envio.enviado
      end
    end
  end
end

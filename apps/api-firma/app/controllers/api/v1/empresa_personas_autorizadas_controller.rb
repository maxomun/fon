# frozen_string_literal: true

module Api
  module V1
    class EmpresaPersonasAutorizadasController < BaseController
      include PersonaAutorizadaSerializable
      include EmpresaAuthorizable

      before_action :require_admin_empresa!
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

        resultado_usuario = PersonasAutorizadas::ProvisionarUsuario.call(persona_autorizada: persona)
        unless resultado_usuario.success?
          return render_error(
            'No se pudo provisionar el usuario de la persona autorizada',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado_usuario.errors
          )
        end

        asignacion = @empresa.empresa_personas_autorizadas.build(
          persona_autorizada: persona,
          es_administrador_empresa: cast_boolean(asignacion_params[:es_administrador_empresa])
        )

        if asignacion.save
          onboarding_email_enviado = false
          if resultado_usuario.created? || resultado_usuario.linked?
            envio = PersonasAutorizadas::EnviarVerificacionEmail.call(user: persona.user)
            onboarding_email_enviado = envio.enviado
          end

          render_success(
            data: persona_autorizada_asignada_payload(persona, asignacion: asignacion),
            status: :created,
            message: mensaje_onboarding(
              onboarding_email_enviado: onboarding_email_enviado,
              accion: :asignada
            )
          )
        else
          render_persona_validation_error(asignacion)
        end
      end

      # PATCH/PUT /api/v1/empresas/:empresa_id/personas_autorizadas/:id
      def update
        asignacion = @empresa.empresa_personas_autorizadas.find_by!(persona_autorizada_id: params[:id])

        if asignacion.update(es_administrador_empresa: cast_boolean(asignacion_params[:es_administrador_empresa]))
          render_success(
            data: persona_autorizada_asignada_payload(asignacion.persona_autorizada, asignacion: asignacion),
            message: 'Permisos de la persona autorizada actualizados exitosamente'
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

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def asignacion_params
        params.require(:persona_autorizada).permit(:persona_autorizada_id, :es_administrador_empresa)
      end

      def cast_boolean(value)
        ActiveModel::Type::Boolean.new.cast(value) || false
      end
    end
  end
end

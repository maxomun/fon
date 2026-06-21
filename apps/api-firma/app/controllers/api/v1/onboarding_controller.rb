# frozen_string_literal: true

module Api
  module V1
    class OnboardingController < BaseController
      skip_before_action :authenticate_request!

      # POST /api/v1/auth/onboarding/verificar-email
      def verificar_email
        resultado = ::Onboarding::VerificarEmail.call(token: verificar_email_params[:token])

        if resultado.success?
          render_success(
            data: {
              setup_token: resultado.setup_token,
              email_verificado: resultado.user.email_verificado?,
              onboarding_completado: resultado.user.onboarding_completado?,
              requiere_onboarding: resultado.user.requiere_onboarding?
            },
            message: 'Correo verificado exitosamente'
          )
        else
          render_error(
            'No se pudo verificar el correo',
            :unprocessable_entity,
            code: 'ONBOARDING_TOKEN_INVALID',
            errors: resultado.errors
          )
        end
      end

      # POST /api/v1/auth/onboarding/establecer-password
      def establecer_password
        attrs = establecer_password_params
        resultado = ::Onboarding::EstablecerPassword.call(
          token: attrs[:token],
          password: attrs[:password],
          password_confirmation: attrs[:password_confirmation]
        )

        if resultado.success?
          render_success(
            data: onboarding_status_payload(resultado.user),
            message: 'Contraseña establecida exitosamente. Ya puede iniciar sesión.'
          )
        else
          Rails.logger.warn(
            "[onboarding] establecer-password falló: #{resultado.errors.join(', ')}"
          )
          render_error(
            resultado.errors.first || 'No se pudo establecer la contraseña',
            :unprocessable_entity,
            code: 'ONBOARDING_PASSWORD_INVALID',
            errors: resultado.errors
          )
        end
      end

      # POST /api/v1/auth/onboarding/reenviar-verificacion
      def reenviar_verificacion
        resultado = ::Onboarding::ReenviarVerificacion.call(
          email: reenviar_verificacion_params[:email]
        )

        render_success(message: resultado.message)
      end

      private

      def verificar_email_params
        onboarding_action_params(:token)
      end

      def establecer_password_params
        onboarding_action_params(:token, :password, :password_confirmation)
      end

      def onboarding_action_params(*keys)
        source = params[:onboarding].present? ? params.require(:onboarding) : params
        source.permit(*keys)
      end

      def reenviar_verificacion_params
        params.permit(:email)
      end

      def onboarding_status_payload(user)
        {
          email_verificado: user.email_verificado?,
          onboarding_completado: user.onboarding_completado?,
          requiere_verificacion_email: user.requiere_verificacion_email?,
          requiere_onboarding: user.requiere_onboarding?,
          debe_cambiar_password: user.debe_cambiar_password
        }
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class PasswordController < BaseController
      skip_before_action :authenticate_request!
      wrap_parameters false

      # POST /api/v1/auth/password/solicitar-restablecimiento
      def solicitar_restablecimiento
        resultado = ::Password::SolicitarRestablecimiento.call(
          email: solicitar_params[:email]
        )

        render_success(
          message: resultado.message,
          code: resultado.code,
          data: { enviado: resultado.enviado }
        )
      end

      # POST /api/v1/auth/password/restablecer
      def restablecer
        attrs = restablecer_params
        resultado = ::Password::Restablecer.call(
          token: attrs[:token],
          password: attrs[:password],
          password_confirmation: attrs[:password_confirmation]
        )

        if resultado.success?
          render_success(message: 'Contraseña restablecida exitosamente. Ya puede iniciar sesión.')
        else
          render_error(
            resultado.errors.first || 'No se pudo restablecer la contraseña',
            :unprocessable_entity,
            code: 'PASSWORD_RESET_INVALID',
            errors: resultado.errors
          )
        end
      end

      private

      def solicitar_params
        password_params.permit(:email)
      end

      def restablecer_params
        password_params.permit(:token, :password, :password_confirmation)
      end

      def password_params
        nested = params[:password]
        nested.is_a?(ActionController::Parameters) ? nested : params
      end
    end
  end
end

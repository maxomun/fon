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

        audit_auth_event(
          Auditoria::Acciones::AUTH_PASSWORD_SOLICITAR,
          resultado: password_solicitar_resultado(resultado),
          metadata: {
            email: solicitar_params[:email].to_s.strip.downcase.presence,
            enviado: resultado.enviado,
            codigo: resultado.code
          },
          codigo_error: resultado.code,
          mensaje: resultado.message
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
          audit_auth_event(
            Auditoria::Acciones::AUTH_PASSWORD_RESTABLECER,
            actor: resultado.user,
            recurso: resultado.user
          )
          render_success(message: 'Contraseña restablecida exitosamente. Ya puede iniciar sesión.')
        else
          audit_auth_event(
            Auditoria::Acciones::AUTH_PASSWORD_RESTABLECER,
            actor: resultado.user,
            recurso: resultado.user,
            resultado: AuditEvent::RESULTADO_FALLO,
            codigo_error: 'PASSWORD_RESET_INVALID',
            mensaje: resultado.errors.first
          )
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

      def password_solicitar_resultado(resultado)
        return AuditEvent::RESULTADO_EXITO if resultado.enviado
        return AuditEvent::RESULTADO_FALLO if resultado.code.present?

        AuditEvent::RESULTADO_EXITO
      end
    end
  end
end

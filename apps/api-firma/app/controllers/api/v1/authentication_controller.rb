# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ApplicationController
      include OnboardingSessionBlockable
      include AuditableAuth

      # No requiere autenticación para login
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_request!, only: [:logout, :me, :refresh]
      before_action :set_current_user_for_refresh, only: [:refresh]

      # POST /api/v1/auth/login
      def login
        user = find_user_by_credentials

        if user&.authenticate(login_params[:password])
          unless user.activo?
            audit_auth_event(
              Auditoria::Acciones::AUTH_LOGIN_BLOQUEADO,
              actor: user,
              recurso: user,
              resultado: AuditEvent::RESULTADO_FALLO,
              codigo_error: 'USER_INACTIVE',
              mensaje: 'Usuario inactivo'
            )
            return render_error('Usuario inactivo', :unauthorized, code: 'USER_INACTIVE')
          end

          bloqueo = Users::VerificarAccesoSesion.call(user)
          if bloqueo
            audit_auth_event(
              Auditoria::Acciones::AUTH_LOGIN_BLOQUEADO,
              actor: user,
              recurso: user,
              resultado: AuditEvent::RESULTADO_FALLO,
              metadata: { bloqueo: bloqueo.code },
              codigo_error: bloqueo.code,
              mensaje: bloqueo.message
            )
            return render_onboarding_blocked(bloqueo, user: user)
          end

          tokens = generate_tokens(user)
          audit_auth_event(
            Auditoria::Acciones::AUTH_LOGIN_EXITOSO,
            actor: user,
            recurso: user,
            metadata: login_identificador_metadata
          )
          render_success(
            tokens.merge(user: user_payload(user)),
            message: 'Inicio de sesión exitoso'
          )
        else
          audit_auth_event(
            Auditoria::Acciones::AUTH_LOGIN_FALLIDO,
            resultado: AuditEvent::RESULTADO_FALLO,
            metadata: login_identificador_metadata,
            codigo_error: 'INVALID_CREDENTIALS',
            mensaje: 'Credenciales inválidas'
          )
          render_error('Credenciales inválidas', :unauthorized, code: 'INVALID_CREDENTIALS')
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        refresh_token_string = params[:refresh_token]

        if refresh_token_string.blank?
          audit_auth_event(
            Auditoria::Acciones::AUTH_REFRESH_TOKEN_INVALIDO,
            resultado: AuditEvent::RESULTADO_FALLO,
            codigo_error: 'REFRESH_TOKEN_REQUIRED',
            mensaje: 'Refresh token requerido'
          )
          return render_error('Refresh token requerido', :bad_request, code: 'REFRESH_TOKEN_REQUIRED')
        end

        refresh_token = RefreshToken.active.find_by(token: refresh_token_string)

        if refresh_token.nil?
          audit_auth_event(
            Auditoria::Acciones::AUTH_REFRESH_TOKEN_INVALIDO,
            resultado: AuditEvent::RESULTADO_FALLO,
            codigo_error: 'INVALID_REFRESH_TOKEN',
            mensaje: 'Refresh token inválido o expirado'
          )
          return render_error('Refresh token inválido o expirado', :unauthorized, code: 'INVALID_REFRESH_TOKEN')
        end

        user = user_scope.find(refresh_token.user_id)

        unless user.activo?
          audit_auth_event(
            Auditoria::Acciones::AUTH_LOGIN_BLOQUEADO,
            actor: user,
            recurso: user,
            resultado: AuditEvent::RESULTADO_FALLO,
            codigo_error: 'USER_INACTIVE',
            mensaje: 'Usuario inactivo'
          )
          return render_error('Usuario inactivo', :unauthorized, code: 'USER_INACTIVE')
        end

        bloqueo = Users::VerificarAccesoSesion.call(user)
        if bloqueo
          refresh_token.revoke!
          audit_auth_event(
            Auditoria::Acciones::AUTH_LOGIN_BLOQUEADO,
            actor: user,
            recurso: user,
            resultado: AuditEvent::RESULTADO_FALLO,
            metadata: { bloqueo: bloqueo.code, origen: 'refresh' },
            codigo_error: bloqueo.code,
            mensaje: bloqueo.message
          )
          return render_onboarding_blocked(bloqueo, user: user)
        end

        refresh_token.revoke!

        tokens = generate_tokens(user)

        audit_auth_event(
          Auditoria::Acciones::AUTH_REFRESH_TOKEN,
          actor: user,
          recurso: user
        )

        render_success(
          tokens.merge(user: user_payload(user)),
          message: 'Tokens renovados exitosamente'
        )
      end

      # DELETE /api/v1/auth/logout
      def logout
        token = extract_token_from_header

        if token.present?
          JsonWebToken.blacklist!(token)
          RefreshToken.revoke_all_for_user!(current_user.id)
        end

        audit_auth_event(
          Auditoria::Acciones::AUTH_LOGOUT,
          actor: current_user,
          recurso: current_user
        )

        render_success(message: 'Sesión cerrada exitosamente')
      end

      # GET /api/v1/auth/me
      def me
        render json: {
          success: true,
          user: user_payload(current_user)
        }, status: :ok
      end

      private

      def login_params
        params.permit(:email, :username, :password)
      end

      def user_scope
        User.includes(:roles, persona_autorizada: :empresa_personas_autorizadas)
      end

      def find_user_by_credentials
        scope = user_scope

        if login_params[:email].present?
          scope.find_by(email: login_params[:email])
        elsif login_params[:username].present?
          scope.find_by(username: login_params[:username])
        end
      end

      def login_identificador_metadata
        if login_params[:email].present?
          { identificador: login_params[:email].to_s.strip.downcase, tipo: 'email' }
        elsif login_params[:username].present?
          { identificador: login_params[:username].to_s.strip, tipo: 'username' }
        else
          { identificador: nil, tipo: nil }
        end
      end

      def generate_tokens(user)
        payload = Users::ProfilePayload.token_claims(user)

        access_token = JsonWebToken.encode_access_token(payload)
        access_exp = JsonWebToken.expiration_time(access_token)

        refresh_token = user.refresh_tokens.create!

        {
          access_token: access_token,
          token_type: 'Bearer',
          expires_at: access_exp.iso8601,
          expires_in: JsonWebToken::ACCESS_TOKEN_EXPIRY.to_i,
          refresh_token: refresh_token.token,
          refresh_expires_at: refresh_token.expires_at.iso8601
        }
      end

      def user_payload(user)
        Users::ProfilePayload.call(user)
      end

      def set_current_user_for_refresh
        # Para refresh, permitimos token expirado para obtener el user_id
      end

      def authenticate_request!
        @current_user = authenticate_token
        Auditoria::Contexto.actor = @current_user
      rescue JsonWebToken::TokenExpiredError
        render_error('Token expirado', :unauthorized, code: 'TOKEN_EXPIRED')
      rescue JsonWebToken::TokenInvalidError => e
        render_error(e.message, :unauthorized, code: 'TOKEN_INVALID')
      rescue OnboardingSessionBlockedError => e
        render_onboarding_blocked(e.bloqueo, user: e.user)
      end

      def authenticate_token
        token = extract_token_from_header
        raise JsonWebToken::TokenInvalidError, 'Token no proporcionado' if token.blank?

        payload = JsonWebToken.decode(token)

        if JsonWebToken.blacklisted?(payload[:jti])
          raise JsonWebToken::TokenInvalidError, 'Token revocado'
        end

        user = user_scope.find_by(id: payload[:user_id])
        raise JsonWebToken::TokenInvalidError, 'Usuario no encontrado' unless user
        raise JsonWebToken::TokenInvalidError, 'Usuario inactivo' unless user.activo?

        enforce_session_onboarding_access!(user)

        user
      end

      def extract_token_from_header
        header = request.headers['Authorization']
        return nil unless header

        header.split(' ').last
      end

      def render_error(message, status, code: nil)
        response = { success: false, message: message }
        response[:code] = code if code
        render json: response, status: status
      end

      def render_success(data = {}, message: nil)
        response = { success: true }
        response[:message] = message if message
        response.merge!(data)
        render json: response, status: :ok
      end

      attr_reader :current_user
    end
  end
end

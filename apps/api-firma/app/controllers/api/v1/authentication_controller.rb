# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ApplicationController
      # No requiere autenticación para login
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_request!, only: [:logout, :me, :refresh]
      before_action :set_current_user_for_refresh, only: [:refresh]

      # POST /api/v1/auth/login
      def login
        user = find_user_by_credentials

        if user&.authenticate(login_params[:password])
          if user.activo?
            tokens = generate_tokens(user)
            render_success(
              tokens.merge(user: user_payload(user)),
              message: 'Inicio de sesión exitoso'
            )
          else
            render_error('Usuario inactivo', :unauthorized, code: 'USER_INACTIVE')
          end
        else
          render_error('Credenciales inválidas', :unauthorized, code: 'INVALID_CREDENTIALS')
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        refresh_token_string = params[:refresh_token]

        if refresh_token_string.blank?
          return render_error('Refresh token requerido', :bad_request, code: 'REFRESH_TOKEN_REQUIRED')
        end

        # Buscar el refresh token en la BD
        refresh_token = RefreshToken.active.find_by(token: refresh_token_string)

        if refresh_token.nil?
          return render_error('Refresh token inválido o expirado', :unauthorized, code: 'INVALID_REFRESH_TOKEN')
        end

        user = refresh_token.user

        unless user.activo?
          return render_error('Usuario inactivo', :unauthorized, code: 'USER_INACTIVE')
        end

        # Revocar el refresh token actual (rotación de tokens)
        refresh_token.revoke!

        # Generar nuevos tokens
        tokens = generate_tokens(user)

        render_success(
          tokens,
          message: 'Tokens renovados exitosamente'
        )
      end

      # DELETE /api/v1/auth/logout
      def logout
        # Extraer token actual
        token = extract_token_from_header

        if token.present?
          # Agregar access token a blacklist
          JsonWebToken.blacklist!(token)

          # Revocar todos los refresh tokens del usuario
          RefreshToken.revoke_all_for_user!(current_user.id)
        end

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

      def find_user_by_credentials
        scope = User.includes(:roles)

        if login_params[:email].present?
          scope.find_by(email: login_params[:email])
        elsif login_params[:username].present?
          scope.find_by(username: login_params[:username])
        end
      end

      def generate_tokens(user)
        payload = token_payload(user)

        # Generar access token (JWT)
        access_token = JsonWebToken.encode_access_token(payload)
        access_exp = JsonWebToken.expiration_time(access_token)

        # Crear refresh token en BD
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

      def token_payload(user)
        {
          user_id: user.id,
          email: user.email,
          username: user.username,
          empresa_id: user.empresa_id,
          roles: user.roles.pluck(:codigo)
        }
      end

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
          lenguaje: user.lenguaje,
          empresa_id: user.empresa_id,
          empresa: user.empresa&.razon_social,
          roles: roles_payload(user),
          persona: user.persona ? {
            nombres: user.persona.nombres,
            apellido_paterno: user.persona.apellido_paterno,
            apellido_materno: user.persona.apellido_materno,
            nombre_completo: user.persona.nombre_completo
          } : nil
        }
      end

      def roles_payload(user)
        user.roles.map do |rol|
          {
            codigo: rol.codigo,
            descripcion: rol.descripcion,
            esadmin: rol.esadmin
          }
        end
      end

      def set_current_user_for_refresh
        # Para refresh, permitimos token expirado para obtener el user_id
      end

      def authenticate_request!
        @current_user = authenticate_token
      rescue JsonWebToken::TokenExpiredError
        render_error('Token expirado', :unauthorized, code: 'TOKEN_EXPIRED')
      rescue JsonWebToken::TokenInvalidError => e
        render_error(e.message, :unauthorized, code: 'TOKEN_INVALID')
      end

      def authenticate_token
        token = extract_token_from_header
        raise JsonWebToken::TokenInvalidError, 'Token no proporcionado' if token.blank?

        payload = JsonWebToken.decode(token)

        if JsonWebToken.blacklisted?(payload[:jti])
          raise JsonWebToken::TokenInvalidError, 'Token revocado'
        end

        user = User.find_by(id: payload[:user_id])
        raise JsonWebToken::TokenInvalidError, 'Usuario no encontrado' unless user

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

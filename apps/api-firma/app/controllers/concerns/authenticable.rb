# frozen_string_literal: true

module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    attr_reader :current_user
  end

  private

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

    # Verificar que sea un access token
    unless payload[:type] == 'access'
      raise JsonWebToken::TokenInvalidError, 'Tipo de token inválido'
    end

    # Verificar blacklist
    if JsonWebToken.blacklisted?(payload[:jti])
      raise JsonWebToken::TokenInvalidError, 'Token revocado'
    end

    # Buscar usuario
    user = User.find_by(id: payload[:user_id])
    raise JsonWebToken::TokenInvalidError, 'Usuario no encontrado' unless user
    raise JsonWebToken::TokenInvalidError, 'Usuario inactivo' unless user.activo?

    user
  end

  def extract_token_from_header
    header = request.headers['Authorization']
    return nil unless header

    # Formato esperado: "Bearer <token>"
    header.split(' ').last
  end

  def render_error(message, status, code: nil, errors: nil)
    response = { 
      success: false,
      message: message 
    }
    response[:code] = code if code
    response[:errors] = errors if errors

    render json: response, status: status
  end

  def render_success(payload = {}, status: :ok, message: nil, **kwargs)
    response = { success: true }
    response[:message] = message if message
    response.merge!(payload) if payload.is_a?(Hash)
    response.merge!(kwargs)

    render json: response, status: status
  end

  # Verificar si el usuario tiene un rol específico
  def authorize_role!(*allowed_roles)
    return if current_user.roles.exists?(codigo: allowed_roles)

    render_error('No tiene permisos para realizar esta acción', :forbidden, code: 'FORBIDDEN')
  end

  # Verificar si es administrador
  def authorize_admin!
    unless current_user.admin?
      render_error('Se requieren permisos de administrador', :forbidden, code: 'ADMIN_REQUIRED')
    end
  end

  # Verificar que el usuario tenga acceso a la empresa (vinculado o administrador FON).
  def authorize_empresa!(empresa_id)
    return if current_user.vinculado_a_empresa?(empresa_id)

    render_error('No tiene acceso a esta empresa', :forbidden, code: 'EMPRESA_FORBIDDEN')
  end

  # Verificar que el usuario pueda administrar datos de la empresa.
  def authorize_admin_empresa!(empresa_id)
    return if current_user.administrador_en_empresa?(empresa_id)

    render_error('No tiene permisos para administrar esta empresa', :forbidden, code: 'EMPRESA_ADMIN_FORBIDDEN')
  end
end

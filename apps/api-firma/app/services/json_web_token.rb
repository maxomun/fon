# frozen_string_literal: true

class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV.fetch('JWT_SECRET_KEY', 'development_secret_key')
  ALGORITHM = 'HS256'

  # Tiempo de expiración de tokens
  ACCESS_TOKEN_EXPIRY = 1.hour
  REFRESH_TOKEN_EXPIRY = 7.days

  class << self
    # Genera un access token (corta duración)
    def encode_access_token(payload)
      encode(payload, ACCESS_TOKEN_EXPIRY, token_type: 'access')
    end

    # Genera un refresh token (larga duración)
    def encode_refresh_token(payload)
      encode(payload, REFRESH_TOKEN_EXPIRY, token_type: 'refresh')
    end

    # Codifica un payload en JWT
    def encode(payload, expiry = ACCESS_TOKEN_EXPIRY, token_type: 'access')
      payload = payload.dup
      payload[:exp] = expiry.from_now.to_i
      payload[:iat] = Time.current.to_i
      payload[:type] = token_type
      payload[:jti] = SecureRandom.uuid # ID único del token para blacklist

      JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end

    # Decodifica un JWT y retorna el payload
    def decode(token)
      decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
      HashWithIndifferentAccess.new(decoded.first)
    rescue JWT::ExpiredSignature
      raise TokenExpiredError, 'El token ha expirado'
    rescue JWT::DecodeError => e
      raise TokenInvalidError, "Token inválido: #{e.message}"
    end

    # Verifica si es un access token válido
    def valid_access_token?(token)
      payload = decode(token)
      payload[:type] == 'access' && !blacklisted?(payload[:jti])
    rescue TokenExpiredError, TokenInvalidError
      false
    end

    # Verifica si es un refresh token válido
    def valid_refresh_token?(token)
      payload = decode(token)
      payload[:type] == 'refresh' && !blacklisted?(payload[:jti])
    rescue TokenExpiredError, TokenInvalidError
      false
    end

    # Verifica si el token está en la blacklist
    def blacklisted?(jti)
      TokenBlacklist.exists?(jti: jti)
    end

    # Agrega un token a la blacklist
    def blacklist!(token)
      payload = decode(token)
      TokenBlacklist.create!(
        jti: payload[:jti],
        exp: Time.at(payload[:exp]),
        user_id: payload[:user_id]
      )
    rescue TokenExpiredError, TokenInvalidError
      # Token ya expirado o inválido, no necesita blacklist
      true
    end

    # Extrae el tiempo de expiración del token
    def expiration_time(token)
      payload = decode(token)
      Time.at(payload[:exp])
    end
  end

  # Excepciones personalizadas
  class TokenExpiredError < StandardError; end
  class TokenInvalidError < StandardError; end
end

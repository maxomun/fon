# frozen_string_literal: true

module Users
  class ValidarPassword
    MIN_LENGTH = 8
    MENSAJE_REQUISITOS =
      'Use al menos 8 caracteres, incluyendo mayúsculas, minúsculas y números.'.freeze

    def self.call(password:)
      new(password: password).call
    end

    def initialize(password:)
      @password = password.to_s
    end

    def call
      errors = []
      normalized = @password.strip

      if normalized != @password
        errors << 'La contraseña no debe tener espacios al inicio o al final'
      end

      if normalized.length < MIN_LENGTH
        errors << "La contraseña debe tener al menos #{MIN_LENGTH} caracteres"
      end

      unless normalized.match?(/[a-z]/)
        errors << 'La contraseña debe incluir al menos una letra minúscula'
      end

      unless normalized.match?(/[A-Z]/)
        errors << 'La contraseña debe incluir al menos una letra mayúscula'
      end

      unless normalized.match?(/\d/)
        errors << 'La contraseña debe incluir al menos un número'
      end

      { valid: errors.empty?, errors: errors }
    end
  end
end

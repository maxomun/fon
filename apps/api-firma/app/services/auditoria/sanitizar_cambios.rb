# frozen_string_literal: true

module Auditoria
  class SanitizarCambios
    CAMPOS_SENSIBLES = %w[
      password
      password_confirmation
      password_digest
      frase_clave
      token
      refresh_token
      access_token
      secret
      archivo_key
      archivo_crs
    ].freeze

    def self.call(valor)
      new(valor).call
    end

    def initialize(valor)
      @valor = valor
    end

    def call
      case @valor
      when Hash
        sanitizar_hash(@valor)
      when Array
        @valor.map { |item| self.class.call(item) }
      else
        @valor
      end
    end

    private

    def sanitizar_hash(hash)
      hash.each_with_object({}) do |(clave, valor), resultado|
        clave_str = clave.to_s
        next if campo_sensible?(clave_str)

        resultado[clave_str] = self.class.call(valor)
      end
    end

    def campo_sensible?(clave)
      clave_down = clave.downcase
      CAMPOS_SENSIBLES.any? { |sensible| clave_down.include?(sensible) }
    end
  end
end

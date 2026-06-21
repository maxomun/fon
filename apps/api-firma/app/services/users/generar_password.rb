# frozen_string_literal: true

module Users
  # Genera una contraseña temporal que cumple Users::ValidarPassword.
  class GenerarPassword
    LOWER = ('a'..'z').to_a.freeze
    UPPER = ('A'..'Z').to_a.freeze
    DIGITS = ('0'..'9').to_a.freeze
    ALL = (LOWER + UPPER + DIGITS).freeze

    DEFAULT_LENGTH = 24

    def self.call(length: DEFAULT_LENGTH)
      new(length: length).call
    end

    def initialize(length: DEFAULT_LENGTH)
      @length = [length, ValidarPassword::MIN_LENGTH].max
    end

    def call
      chars = [
        LOWER.sample(random: SecureRandom),
        UPPER.sample(random: SecureRandom),
        DIGITS.sample(random: SecureRandom)
      ]

      remaining = @length - chars.length
      chars.concat(Array.new(remaining) { ALL.sample(random: SecureRandom) })
      chars.shuffle(random: SecureRandom).join
    end
  end
end

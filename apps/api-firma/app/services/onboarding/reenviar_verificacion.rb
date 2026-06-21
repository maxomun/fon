# frozen_string_literal: true

module Onboarding
  class ReenviarVerificacion
    MENSAJE_GENERICO =
      'Si el correo está registrado y pendiente de verificación, recibirás un enlace en breve.'

    COOLDOWN_MINUTES = 5

    Result = Struct.new(:message, :enviado, keyword_init: true) do
      def success?
        true
      end
    end

    def self.call(email:)
      new(email: email).call
    end

    def initialize(email:)
      @email = email.to_s.strip
    end

    def call
      user = User.find_by('LOWER(email) = ?', @email.downcase)

      if user&.requiere_verificacion_email? && !rate_limited?(user)
        PersonasAutorizadas::EnviarVerificacionEmail.call(user: user)
      end

      Result.new(message: MENSAJE_GENERICO, enviado: false)
    end

    private

    def rate_limited?(user)
      ultimo = user
        .onboarding_tokens
        .verificar_email
        .order(created_at: :desc)
        .first

      ultimo.present? && ultimo.created_at > COOLDOWN_MINUTES.minutes.ago
    end
  end
end

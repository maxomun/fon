# frozen_string_literal: true

module OnboardingTokens
  # Emite un token de onboarding de un solo uso para un usuario.
  #
  # Ejemplo:
  #   resultado = OnboardingTokens::Crear.call(
  #     user: user,
  #     proposito: OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
  #   )
  #   resultado.raw_token # enviar por correo
  #
  class Crear
    Result = Struct.new(:token_record, :raw_token, keyword_init: true)

    def self.call(user:, proposito:, expiry_hours: nil)
      new(user: user, proposito: proposito, expiry_hours: expiry_hours).call
    end

    def initialize(user:, proposito:, expiry_hours: nil)
      @user = user
      @proposito = proposito
      @expiry_hours = expiry_hours
    end

    def call
      raw_token = SecureRandom.urlsafe_base64(32)
      expires_at = expiry_hours.hours.from_now

      token_record = nil

      OnboardingToken.transaction do
        invalidar_tokens_activos!
        token_record = @user.onboarding_tokens.create!(
          token_digest: OnboardingToken.digest(raw_token),
          proposito: @proposito,
          expires_at: expires_at
        )
      end

      Result.new(token_record: token_record, raw_token: raw_token)
    end

    private

    def expiry_hours
      @expiry_hours || MailerConfig.onboarding_token_expiry_hours
    end

    def invalidar_tokens_activos!
      @user
        .onboarding_tokens
        .activos
        .where(proposito: @proposito)
        .find_each(&:consumir!)
    end
  end
end

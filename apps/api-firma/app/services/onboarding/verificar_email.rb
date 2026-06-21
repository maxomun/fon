# frozen_string_literal: true

module Onboarding
  class VerificarEmail
    Result = Struct.new(:setup_token, :user, :errors, keyword_init: true) do
      def success?
        errors.blank? && setup_token.present?
      end
    end

    def self.call(token:)
      new(token: token).call
    end

    def initialize(token:)
      @token = token.to_s.strip
    end

    def call
      if @token.blank?
        return failure(['Token requerido'])
      end

      onboarding_token = OnboardingToken.find_by_raw_token(@token)
      return failure(['Token inválido']) if onboarding_token.nil?

      if onboarding_token.consumido?
        return failure(['Token ya utilizado'])
      end

      if onboarding_token.expirado?
        return failure(['Token expirado'])
      end

      unless onboarding_token.proposito == OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
        return failure(['Token inválido'])
      end

      user = onboarding_token.user
      setup_token = nil

      User.transaction do
        onboarding_token.consumir!

        unless user.email_verificado?
          user.update!(email_verificado_at: Time.current)
        end

        setup = OnboardingTokens::Crear.call(
          user: user,
          proposito: OnboardingToken::PROPOSITO_ESTABLECER_PASSWORD
        )
        setup_token = setup.raw_token
      end

      Result.new(setup_token: setup_token, user: user, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def failure(errors)
      Result.new(setup_token: nil, user: nil, errors: Array(errors))
    end
  end
end

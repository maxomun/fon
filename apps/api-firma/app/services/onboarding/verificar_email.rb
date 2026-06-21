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

      unless onboarding_token.proposito == OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
        return failure(['Token inválido'])
      end

      setup_token = nil
      user = onboarding_token.user

      User.transaction do
        onboarding_token.lock!

        if onboarding_token.consumido?
          user.reload
          if user.email_verificado? && !user.onboarding_completado?
            return failure([
              'El correo ya fue verificado. Continúe con el enlace para establecer su contraseña.'
            ])
          end

          return failure(['Token ya utilizado'])
        end

        if onboarding_token.expirado?
          return failure(['Token expirado'])
        end

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

      Result.new(setup_token: setup_token, user: user.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def failure(errors)
      Result.new(setup_token: nil, user: nil, errors: Array(errors))
    end
  end
end

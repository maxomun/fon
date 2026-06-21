# frozen_string_literal: true

module PersonasAutorizadas
  # Envía correo con enlace para definir contraseña (paso 2 del onboarding).
  class EnviarEstablecerPasswordEmail
    Result = Struct.new(:enviado, :errors, keyword_init: true) do
      def success?
        errors.blank? && enviado
      end
    end

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      unless @user.email_verificado?
        return Result.new(
          enviado: false,
          errors: ['El correo aún no está verificado']
        )
      end

      if @user.onboarding_completado?
        return Result.new(enviado: false, errors: [])
      end

      unless MailerConfig.smtp_configured?
        return Result.new(
          enviado: false,
          errors: ['Configure SMTP_USERNAME y SMTP_PASSWORD para enviar correos de onboarding']
        )
      end

      token = OnboardingTokens::Crear.call(
        user: @user,
        proposito: OnboardingToken::PROPOSITO_ESTABLECER_PASSWORD
      )

      PersonaAutorizadaOnboardingMailer
        .establecer_password(user: @user, raw_token: token.raw_token)
        .deliver_now

      Result.new(enviado: true, errors: [])
    rescue StandardError => e
      Rails.logger.error("[onboarding] Error enviando establecer password a #{@user.email}: #{e.message}")
      Result.new(enviado: false, errors: [e.message])
    end
  end
end

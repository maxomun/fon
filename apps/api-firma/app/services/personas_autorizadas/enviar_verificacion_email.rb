# frozen_string_literal: true

module PersonasAutorizadas
  # Genera token y envía el correo de verificación de email para onboarding.
  class EnviarVerificacionEmail
    Result = Struct.new(:enviado, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      unless @user.requiere_verificacion_email?
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
        proposito: OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
      )

      PersonaAutorizadaOnboardingMailer
        .verificacion_email(user: @user, raw_token: token.raw_token)
        .deliver_now

      Result.new(enviado: true, errors: [])
    rescue StandardError => e
      Rails.logger.error("[onboarding] Error enviando verificación a #{@user.email}: #{e.message}")
      Result.new(enviado: false, errors: [e.message])
    end
  end
end

# frozen_string_literal: true

module Password
  class SolicitarRestablecimiento
    MENSAJE_GENERICO =
      'Si el correo está registrado, recibirás instrucciones para restablecer tu contraseña.'

    MENSAJE_ONBOARDING_EMAIL_PENDIENTE =
      'Su cuenta aún no ha verificado el correo. Revise su bandeja de entrada o solicite ' \
      'un nuevo correo de verificación desde el inicio de sesión.'

    MENSAJE_ONBOARDING_INCOMPLETO =
      'Debe completar el enrolamiento antes de restablecer la contraseña. ' \
      'Revise su correo para los pasos pendientes o contacte al administrador.'

    MENSAJE_RATE_LIMITED =
      'Ya enviamos un enlace recientemente. Revise su correo (y spam) o espere unos minutos ' \
      'antes de solicitar otro.'

    COOLDOWN_MINUTES = 5

    CODIGO_ONBOARDING_EMAIL = 'ONBOARDING_EMAIL_PENDIENTE'
    CODIGO_ONBOARDING_INCOMPLETO = 'ONBOARDING_INCOMPLETO'
    CODIGO_RATE_LIMITED = 'PASSWORD_RESET_RATE_LIMITED'

    Result = Struct.new(:message, :code, :enviado, keyword_init: true) do
      def success?
        true
      end
    end

    def self.call(email:)
      new(email: email).call
    end

    def initialize(email:)
      @email = email.to_s.strip.downcase
    end

    def call
      if @email.blank?
        return Result.new(message: MENSAJE_GENERICO, code: nil, enviado: false)
      end

      user = User.find_by('LOWER(email) = ?', @email)

      if user.nil? || !user.activo?
        return Result.new(message: MENSAJE_GENERICO, code: nil, enviado: false)
      end

      if user.requiere_verificacion_email?
        return Result.new(
          message: MENSAJE_ONBOARDING_EMAIL_PENDIENTE,
          code: CODIGO_ONBOARDING_EMAIL,
          enviado: false
        )
      end

      if user.requiere_onboarding?
        return Result.new(
          message: MENSAJE_ONBOARDING_INCOMPLETO,
          code: CODIGO_ONBOARDING_INCOMPLETO,
          enviado: false
        )
      end

      enviado = false

      if rate_limited?(user)
        return Result.new(
          message: MENSAJE_RATE_LIMITED,
          code: CODIGO_RATE_LIMITED,
          enviado: false
        )
      end

      if MailerConfig.smtp_configured?
        token = OnboardingTokens::Crear.call(
          user: user,
          proposito: OnboardingToken::PROPOSITO_RESTABLECER_PASSWORD,
          expiry_hours: MailerConfig.password_reset_token_expiry_hours
        )

        begin
          PersonaAutorizadaOnboardingMailer
            .restablecer_password(user: user, raw_token: token.raw_token)
            .deliver_now
        rescue StandardError => e
          token.token_record.destroy
          raise e
        end

        enviado = true
      end

      Result.new(message: MENSAJE_GENERICO, code: nil, enviado: enviado)
    rescue StandardError => e
      Rails.logger.error(
        "[password] Error enviando restablecimiento a #{@email}: #{e.class}: #{e.message}"
      )
      Result.new(message: MENSAJE_GENERICO, code: nil, enviado: false)
    end

    private

    def rate_limited?(user)
      user
        .onboarding_tokens
        .restablecer_password
        .activos
        .where('created_at > ?', COOLDOWN_MINUTES.minutes.ago)
        .exists?
    end
  end
end

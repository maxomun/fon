# frozen_string_literal: true

class PersonaAutorizadaOnboardingMailer < ApplicationMailer
  def verificacion_email(user:, raw_token:)
    @user = user
    @nombre = user.nombre_completo.presence || user.email
    @expiry_hours = MailerConfig.onboarding_token_expiry_hours
    @verification_url = verification_url(raw_token)

    mail(
      to: user.email,
      subject: 'Confirma tu correo en FacturaOn'
    )
  end

  def establecer_password(user:, raw_token:)
    @user = user
    @nombre = user.nombre_completo.presence || user.email
    @expiry_hours = MailerConfig.onboarding_token_expiry_hours
    @password_url = password_url(raw_token)

    mail(
      to: user.email,
      subject: 'Establece tu contraseña en FacturaOn'
    )
  end

  private

  def verification_url(raw_token)
    "#{MailerConfig.frontend_base_url}/onboarding/verificar-email?token=#{CGI.escape(raw_token)}"
  end

  def password_url(raw_token)
    "#{MailerConfig.frontend_base_url}/onboarding/establecer-password?token=#{CGI.escape(raw_token)}"
  end
end

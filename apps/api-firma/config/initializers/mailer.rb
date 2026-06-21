# frozen_string_literal: true

module MailerConfig
  module_function

  def from_email
    ENV.fetch('MAIL_FROM', 'noreply@example.com')
  end

  def from_name
    ENV.fetch('MAIL_FROM_NAME', 'FacturaOn Enrolamiento')
  end

  def from_address
    ActionMailer::Base.email_address_with_name(from_email, from_name)
  end

  def frontend_base_url
    ENV.fetch('FRONTEND_BASE_URL', 'http://localhost:5173').chomp('/')
  end

  def onboarding_token_expiry_hours
    ENV.fetch('ONBOARDING_TOKEN_EXPIRY_HOURS', 48).to_i
  end

  def password_reset_token_expiry_hours
    ENV.fetch('PASSWORD_RESET_TOKEN_EXPIRY_HOURS', 24).to_i
  end

  def smtp_configured?
    ENV['SMTP_USERNAME'].present? && ENV['SMTP_PASSWORD'].present?
  end

  def smtp_settings
    {
      address: ENV.fetch('SMTP_ADDRESS', 'smtp.gmail.com'),
      port: ENV.fetch('SMTP_PORT', 587).to_i,
      domain: ENV.fetch('SMTP_DOMAIN', 'gmail.com'),
      user_name: ENV.fetch('SMTP_USERNAME'),
      password: smtp_password,
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain').to_sym,
      enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(
        ENV.fetch('SMTP_ENABLE_STARTTLS', true)
      ),
      open_timeout: ENV.fetch('SMTP_OPEN_TIMEOUT', 30).to_i,
      read_timeout: ENV.fetch('SMTP_READ_TIMEOUT', 30).to_i
    }
  end

  def smtp_password
    ENV.fetch('SMTP_PASSWORD', '').gsub(/\s+/, '')
  end
end

Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: URI.parse(MailerConfig.frontend_base_url).host,
    port: URI.parse(MailerConfig.frontend_base_url).port,
    protocol: URI.parse(MailerConfig.frontend_base_url).scheme
  }

  if MailerConfig.smtp_configured?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = MailerConfig.smtp_settings
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true
  else
    config.action_mailer.delivery_method = :test
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.perform_deliveries = false
  end
end

# frozen_string_literal: true

namespace :mailer do
  desc 'Envía un correo de prueba de verificación de onboarding (EMAIL=usuario@ejemplo.cl)'
  task test_onboarding: :environment do
    email = ENV.fetch('EMAIL', nil)

    if email.blank?
      puts 'Error: indique el destinatario con EMAIL=usuario@ejemplo.cl'
      exit 1
    end

    unless MailerConfig.smtp_configured?
      puts 'Error: configure SMTP_USERNAME y SMTP_PASSWORD en .env antes de probar el envío.'
      exit 1
    end

    user = User.find_by(email: email)

    unless user
      puts "Error: no existe un usuario con email #{email}"
      exit 1
    end

    resultado = OnboardingTokens::Crear.call(
      user: user,
      proposito: OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
    )

    PersonaAutorizadaOnboardingMailer
      .verificacion_email(user: user, raw_token: resultado.raw_token)
      .deliver_now

    puts 'Correo de prueba enviado.'
    puts "Destinatario: #{email}"
    puts "Token emitido (solo para depuración local): #{resultado.raw_token}"
  end

  desc 'Muestra la configuración SMTP cargada (sin secretos)'
  task config: :environment do
    puts '=== Configuración de correo ==='
    puts "SMTP configurado: #{MailerConfig.smtp_configured? ? 'sí' : 'no'}"
    puts "From: #{MailerConfig.from_address}"
    puts "Frontend base URL: #{MailerConfig.frontend_base_url}"
    puts "Expiración token onboarding: #{MailerConfig.onboarding_token_expiry_hours} h"
    puts "Delivery method: #{ActionMailer::Base.delivery_method}"

    if MailerConfig.smtp_configured?
      settings = MailerConfig.smtp_settings
      puts "SMTP address: #{settings[:address]}:#{settings[:port]}"
      puts "SMTP user: #{settings[:user_name]}"
    end
  end
end

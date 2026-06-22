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

  desc 'Genera HTML de vista previa de los correos en tmp/mailer_previews/'
  task preview: :environment do
    user = User.order(:id).first

    unless user
      puts 'Error: no hay usuarios en la base de datos para generar la vista previa.'
      exit 1
    end

    output_dir = Rails.root.join('tmp/mailer_previews')
    FileUtils.mkdir_p(output_dir)

    previews = {
      'verificacion_email.html' => PersonaAutorizadaOnboardingMailer.verificacion_email(
        user: user,
        raw_token: 'preview-token-verificacion'
      ),
      'establecer_password.html' => PersonaAutorizadaOnboardingMailer.establecer_password(
        user: user,
        raw_token: 'preview-token-password'
      ),
      'restablecer_password.html' => PersonaAutorizadaOnboardingMailer.restablecer_password(
        user: user,
        raw_token: 'preview-token-reset'
      )
    }

    previews.each do |filename, mail|
      html = mail.html_part&.body&.to_s || mail.body.to_s
      path = output_dir.join(filename)
      File.write(path, html)
      puts "Generado: #{path}"
    end

    puts ''
    puts 'Abra los archivos HTML en el navegador para revisar el diseño.'
    puts 'Nota: el logo embebido (cid:) solo se ve en clientes de correo reales, no en el HTML guardado.'
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

    puts "Logo embebido: #{MailerConfig.logo_file_path} (#{File.exist?(MailerConfig.logo_file_path) ? 'ok' : 'no encontrado'})"
    puts "Logo URL externo: #{MailerConfig.logo_url || '(no configurado; se usa embebido)'}"
  end

  desc 'Prueba conexión TCP y autenticación SMTP (sin enviar correo)'
  task test_auth: :environment do
    unless MailerConfig.smtp_configured?
      puts 'Error: configure SMTP_USERNAME y SMTP_PASSWORD en .env'
      exit 1
    end

    settings = MailerConfig.smtp_settings
    user = settings[:user_name]
    pass = settings[:password]

    puts '=== Diagnóstico SMTP (sin mostrar secretos) ==='
    puts "Usuario: #{user}"
    puts "Longitud password: #{pass.length} caracteres"
    puts "Password con espacios: #{pass.match?(/\s/) ? 'sí (quitar)' : 'no'}"
    puts "MAIL_FROM: #{MailerConfig.from_email}"
    puts "From = SMTP user: #{MailerConfig.from_email == user ? 'sí' : 'no (revisar)'}"
    puts ''

    host = settings[:address]
    port = settings[:port]

    begin
      Timeout.timeout(10) do
        socket = TCPSocket.new(host, port)
        banner = socket.gets
        socket.close
        puts "TCP #{host}:#{port} -> OK (#{banner&.strip})"
      end
    rescue StandardError => e
      puts "TCP #{host}:#{port} -> FALLO (#{e.class}: #{e.message})"
      exit 1
    end

    puts ''
    puts 'Autenticación SMTP...'

    begin
      smtp = Net::SMTP.new(host, port)
      smtp.open_timeout = settings[:open_timeout]
      smtp.read_timeout = settings[:read_timeout]
      smtp.enable_starttls_auto if settings[:enable_starttls_auto]
      smtp.start(settings[:domain], user, pass, settings[:authentication]) do
        puts 'RESULTADO: AUTH OK — Gmail aceptó usuario y contraseña'
      end
    rescue Net::SMTPAuthenticationError => e
      puts "RESULTADO: AUTH FALLÓ — #{e.message.lines.first&.strip}"
      puts ''
      puts 'La red llega a Gmail, pero la cuenta rechaza las credenciales.'
      puts 'Revise en https://myaccount.google.com/apppasswords :'
      puts '  - Verificación en 2 pasos activa'
      puts '  - App Password nueva (16 caracteres, sin espacios)'
      puts '  - Generada para la misma cuenta que SMTP_USERNAME'
      puts '  - No revocada (cambiar contraseña de Google la invalida)'
      exit 1
    rescue StandardError => e
      puts "RESULTADO: ERROR — #{e.class}: #{e.message.lines.first&.strip}"
      exit 1
    end
  end
end

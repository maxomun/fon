# frozen_string_literal: true

module Users
  # Crea un usuario operador de plataforma (sin persona autorizada).
  class CrearOperador
    DEFAULT_LENGUAGE = 'es'

    Result = Struct.new(:user, :errors, :password_generada, :acceso_enviado, keyword_init: true) do
      def success?
        errors.blank? && user&.persisted?
      end
    end

    def self.call(attributes:, enviar_acceso: false)
      new(attributes: attributes, enviar_acceso: enviar_acceso).call
    end

    def initialize(attributes:, enviar_acceso: false)
      @attributes = attributes.to_h.symbolize_keys
      @enviar_acceso = enviar_acceso
    end

    def call
      if User.exists?(['LOWER(email) = ?', @attributes[:email].to_s.strip.downcase])
        return failure(['El email ya está registrado'])
      end

      password_generada = @attributes[:password].blank?
      if password_generada && !@enviar_acceso
        return failure(['Debe indicar contraseña o solicitar envío de acceso por correo'])
      end

      password = @attributes[:password].presence || GenerarPassword.call
      user = nil
      acceso_enviado = false

      User.transaction do
        user = User.create!(
          email: @attributes[:email].to_s.strip.downcase,
          username: username_para(@attributes),
          password: password,
          password_confirmation: password,
          lenguaje: @attributes[:lenguaje].presence || DEFAULT_LENGUAGE,
          estado: User::ESTADO_ACTIVO,
          visible: cast_boolean(@attributes[:visible], default: true),
          nombres: @attributes[:nombres],
          apellido_paterno: @attributes[:apellido_paterno],
          apellido_materno: @attributes[:apellido_materno],
          email_verificado_at: Time.current,
          onboarding_completado_at: Time.current,
          debe_cambiar_password: password_generada
        )

        GestionRolesFon.sincronizar!(
          user,
          asignar: cast_boolean(@attributes[:administrador_fon], default: true)
        )
      end

      if @enviar_acceso
        resultado = ReenviarAcceso.call(user: user)
        acceso_enviado = resultado.enviado
      end

      Result.new(
        user: user.reload,
        errors: [],
        password_generada: password_generada,
        acceso_enviado: acceso_enviado
      )
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    rescue StandardError => e
      failure([e.message])
    end

    private

    def username_para(attributes)
      explicito = attributes[:username].to_s.strip
      return explicito[0, 50] if explicito.present?

      generar_username_unico(attributes[:email].to_s)
    end

    def generar_username_unico(email)
      base = email.to_s.split('@').first.to_s.parameterize(separator: '_')
      base = "operador_#{SecureRandom.hex(3)}" if base.blank?

      candidate = base[0, 50]
      return candidate unless User.exists?(username: candidate)

      suffix = 1
      loop do
        truncated = base[0, [1, 50 - suffix.to_s.length - 1].max]
        candidate = "#{truncated}_#{suffix}"
        return candidate unless User.exists?(username: candidate)

        suffix += 1
      end
    end

    def cast_boolean(value, default: false)
      return default if value.nil?

      ActiveModel::Type::Boolean.new.cast(value)
    end

    def failure(errors)
      Result.new(user: nil, errors: Array(errors), password_generada: false, acceso_enviado: false)
    end
  end
end

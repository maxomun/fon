# frozen_string_literal: true

module PersonasAutorizadas
  # Crea (o reutiliza) la cuenta de login asociada a una persona autorizada.
  #
  # Ejemplo:
  #   resultado = PersonasAutorizadas::ProvisionarUsuario.call(persona_autorizada: persona)
  #
  class ProvisionarUsuario
    DEFAULT_LENGUAGE = 'es'
    DEFAULT_PASSWORD_ENV = 'PERSONA_AUTORIZADA_DEFAULT_PASSWORD'

    Result = Struct.new(:user, :errors, :action, keyword_init: true) do
      def success?
        errors.blank? && user.present?
      end

      def created?
        action == :created
      end

      def linked?
        action == :linked
      end
    end

    def self.call(persona_autorizada:, password: nil)
      new(persona_autorizada: persona_autorizada, password: password).call
    end

    def initialize(persona_autorizada:, password: nil)
      @persona_autorizada = persona_autorizada
      @password = password
    end

    def call
      if @persona_autorizada.user.present?
        sincronizar_datos_en_usuario(@persona_autorizada.user)
        return Result.new(user: @persona_autorizada.user, errors: [], action: :synced)
      end

      existing_user = User.find_by(email: @persona_autorizada.email)
      if existing_user
        return vincular_usuario_existente(existing_user)
      end

      password = provisioning_password

      user = nil

      PersonaAutorizada.transaction do
        user = User.create!(
          email: @persona_autorizada.email,
          username: generar_username(@persona_autorizada),
          password: password,
          password_confirmation: password,
          lenguaje: DEFAULT_LENGUAGE,
          estado: User::ESTADO_ACTIVO,
          visible: true,
          nombres: @persona_autorizada.nombres,
          apellido_paterno: @persona_autorizada.apellido_paterno,
          apellido_materno: @persona_autorizada.apellido_materno,
          email_verificado_at: nil,
          onboarding_completado_at: nil,
          debe_cambiar_password: true
        )

        @persona_autorizada.update!(user: user)
      end

      Result.new(user: user, errors: [], action: :created)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def vincular_usuario_existente(user)
      otra_persona = user.persona_autorizada
      if otra_persona.present? && otra_persona.id != @persona_autorizada.id
        return failure([
          "El email #{@persona_autorizada.email} ya está asociado a otra persona autorizada (id=#{otra_persona.id})"
        ])
      end

      PersonaAutorizada.transaction do
        @persona_autorizada.update!(user: user)
        sincronizar_datos_en_usuario(user)
      end

      Result.new(user: user, errors: [], action: :linked)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    def sincronizar_datos_en_usuario(user)
      user.update!(
        nombres: @persona_autorizada.nombres,
        apellido_paterno: @persona_autorizada.apellido_paterno,
        apellido_materno: @persona_autorizada.apellido_materno,
        email: @persona_autorizada.email
      )
    end

    def generar_username(persona)
      base = persona.email.to_s.split('@').first.to_s.parameterize(separator: '_')
      base = persona.rut.to_s.gsub(/[^0-9kK]/, '').downcase if base.blank?
      base = "persona_#{persona.id || SecureRandom.hex(3)}" if base.blank?

      ensure_unique_username(base)
    end

    def ensure_unique_username(base)
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

    def default_password
      ENV.fetch(DEFAULT_PASSWORD_ENV, nil).presence
    end

    def provisioning_password
      return @password if @password.present?

      env_password = default_password
      if env_password.present?
        resultado = Users::ValidarPassword.call(password: env_password)
        return env_password if resultado[:valid]

        Rails.logger.warn(
          "[provisionar_usuario] #{DEFAULT_PASSWORD_ENV} no cumple la política de contraseña; " \
          'se generará una temporal.'
        )
      end

      Users::GenerarPassword.call
    end

    def failure(errors)
      Result.new(user: nil, errors: Array(errors))
    end
  end
end

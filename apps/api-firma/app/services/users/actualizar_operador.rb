# frozen_string_literal: true

module Users
  # Actualiza un usuario operador de plataforma (sin persona autorizada).
  class ActualizarOperador
    Result = Struct.new(:user, :errors, keyword_init: true) do
      def success?
        errors.blank? && user.present?
      end
    end

    def self.call(user:, attributes:)
      new(user: user, attributes: attributes).call
    end

    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      return failure(['Este usuario está vinculado a una persona autorizada y no se edita desde aquí']) if @user.persona_autorizada.present?

      User.transaction do
        @user.assign_attributes(atributos_perfil)
        @user.password = @attributes[:password] if @attributes[:password].present?
        @user.password_confirmation = @attributes[:password_confirmation] if @attributes[:password_confirmation].present?

        if @attributes[:password].present?
          @user.debe_cambiar_password = false
          @user.email_verificado_at ||= Time.current
          @user.onboarding_completado_at ||= Time.current
        end

        @user.save!

        if @attributes.key?(:administrador_fon)
          GestionRolesFon.sincronizar!(@user, asignar: @attributes[:administrador_fon])
        end
      end

      Result.new(user: @user.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    rescue StandardError => e
      failure([e.message])
    end

    private

    def atributos_perfil
      permitted = {}

      %i[email username nombres apellido_paterno apellido_materno lenguaje visible].each do |key|
        permitted[key] = @attributes[key] if @attributes.key?(key)
      end

      permitted[:email] = permitted[:email].to_s.strip.downcase if permitted[:email].present?
      permitted
    end

    def failure(errors)
      Result.new(user: @user, errors: Array(errors))
    end
  end
end

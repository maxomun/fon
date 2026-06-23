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
      if @user.persona_autorizada.present?
        return auditar_fallo(
          failure(['Este usuario está vinculado a una persona autorizada y no se edita desde aquí'])
        )
      end

      tenia_rol_fon = @user.administrador_fon?

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

      resultado = Result.new(user: @user.reload, errors: [])
      auditar_exito(resultado, tenia_rol_fon: tenia_rol_fon)
      resultado
    rescue ActiveRecord::RecordInvalid => e
      auditar_fallo(failure(e.record.errors.full_messages))
    rescue StandardError => e
      auditar_fallo(failure([e.message]))
    end

    private

    def auditar_exito(resultado, tenia_rol_fon:)
      cambios = Auditoria::Cambios.desde_modelo(resultado.user)
      cambios['password'] = [nil, '[actualizada]'] if @attributes[:password].present?

      Auditoria::RegistrarUsuario.call(
        accion: Auditoria::Acciones::USUARIO_ACTUALIZAR,
        user: resultado.user,
        cambios: cambios,
        metadata: {
          rol_fon_antes: tenia_rol_fon,
          rol_fon_despues: resultado.user.administrador_fon?
        }
      )
    end

    def auditar_fallo(resultado)
      Auditoria::RegistrarUsuario.call(
        accion: Auditoria::Acciones::USUARIO_ACTUALIZAR,
        user: @user,
        resultado: AuditEvent::RESULTADO_FALLO,
        mensaje: resultado.errors.join(', ')
      )
      resultado
    end

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

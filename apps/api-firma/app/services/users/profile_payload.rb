# frozen_string_literal: true

module Users
  class ProfilePayload
    def self.call(user)
      new(user).call
    end

    def self.token_claims(user)
      new(user).token_claims
    end

    def initialize(user)
      @user = user
    end

    def call
      {
        id: @user.id,
        email: @user.email,
        username: @user.username,
        lenguaje: @user.lenguaje,
        nombres: @user.nombres,
        apellido_paterno: @user.apellido_paterno,
        apellido_materno: @user.apellido_materno,
        nombre_completo: @user.nombre_completo.presence,
        persona_autorizada_id: @user.persona_autorizada&.id,
        acceso_global: @user.administrador_fon?,
        empresas: Users::EmpresasPayload.call(@user),
        roles: roles_payload,
        email_verificado: @user.email_verificado?,
        onboarding_completado: @user.onboarding_completado?,
        requiere_verificacion_email: @user.requiere_verificacion_email?,
        requiere_onboarding: @user.requiere_onboarding?,
        debe_cambiar_password: @user.debe_cambiar_password
      }
    end

    def token_claims
      {
        user_id: @user.id,
        email: @user.email,
        username: @user.username,
        acceso_global: @user.administrador_fon?,
        roles: @user.roles.pluck(:codigo)
      }
    end

    private

    def roles_payload
      @user.roles.map do |rol|
        {
          codigo: rol.codigo,
          descripcion: rol.descripcion,
          esadmin: rol.esadmin
        }
      end
    end
  end
end

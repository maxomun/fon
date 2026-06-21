# frozen_string_literal: true

module Users
  class VerificarAccesoSesion
    Blocked = Struct.new(:message, :code, keyword_init: true)

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return nil unless @user.perfil_persona_autorizada?

      if @user.requiere_verificacion_email?
        return Blocked.new(
          message: 'Debe verificar su correo antes de ingresar',
          code: 'EMAIL_NOT_VERIFIED'
        )
      end

      unless @user.onboarding_completado?
        return Blocked.new(
          message: 'Debe completar el enrolamiento antes de ingresar',
          code: 'ONBOARDING_INCOMPLETE'
        )
      end

      nil
    end
  end
end

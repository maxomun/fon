# frozen_string_literal: true

module Users
  # Envía correo de restablecimiento de contraseña a un operador de plataforma.
  class ReenviarAcceso
    Result = Struct.new(:enviado, :message, :code, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      if @user.persona_autorizada.present?
        return auditar_fallo(
          Result.new(
            enviado: false,
            message: nil,
            code: 'NOT_PLATFORM_USER',
            errors: ['Use el flujo de enrolamiento de personas autorizadas']
          )
        )
      end

      unless @user.activo?
        return auditar_fallo(
          Result.new(
            enviado: false,
            message: nil,
            code: 'USER_INACTIVE',
            errors: ['El usuario está inactivo']
          )
        )
      end

      resultado = Password::SolicitarRestablecimiento.call(email: @user.email)

      if resultado.code.present? && !resultado.enviado
        return auditar_fallo(
          Result.new(
            enviado: false,
            message: resultado.message,
            code: resultado.code,
            errors: [resultado.message]
          )
        )
      end

      resultado_final = Result.new(
        enviado: resultado.enviado,
        message: resultado.message,
        code: resultado.code,
        errors: []
      )
      auditar_exito(resultado_final)
      resultado_final
    end

    private

    def auditar_exito(resultado)
      Auditoria::RegistrarUsuario.call(
        accion: Auditoria::Acciones::USUARIO_REENVIAR_ACCESO,
        user: @user,
        metadata: { enviado: resultado.enviado, codigo: resultado.code }
      )
    end

    def auditar_fallo(resultado)
      Auditoria::RegistrarUsuario.call(
        accion: Auditoria::Acciones::USUARIO_REENVIAR_ACCESO,
        user: @user,
        resultado: AuditEvent::RESULTADO_FALLO,
        codigo_error: resultado.code,
        mensaje: resultado.errors&.first || resultado.message,
        metadata: { enviado: resultado.enviado }
      )
      resultado
    end
  end
end

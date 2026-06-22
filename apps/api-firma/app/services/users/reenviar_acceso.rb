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
        return Result.new(
          enviado: false,
          message: nil,
          code: 'NOT_PLATFORM_USER',
          errors: ['Use el flujo de enrolamiento de personas autorizadas']
        )
      end

      unless @user.activo?
        return Result.new(
          enviado: false,
          message: nil,
          code: 'USER_INACTIVE',
          errors: ['El usuario está inactivo']
        )
      end

      resultado = Password::SolicitarRestablecimiento.call(email: @user.email)

      if resultado.code.present? && !resultado.enviado
        return Result.new(
          enviado: false,
          message: resultado.message,
          code: resultado.code,
          errors: [resultado.message]
        )
      end

      Result.new(
        enviado: resultado.enviado,
        message: resultado.message,
        code: resultado.code,
        errors: []
      )
    end
  end
end

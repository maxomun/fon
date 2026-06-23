# frozen_string_literal: true

module PersonasAutorizadas
  # Reenvía el correo correspondiente al paso pendiente del onboarding.
  class ReenviarOnboarding
    Result = Struct.new(:enviado, :paso, :errors, keyword_init: true) do
      def success?
        errors.blank? && enviado
      end
    end

    PASO_VERIFICACION = 'verificar_email'
    PASO_PASSWORD = 'establecer_password'

    def self.call(persona_autorizada:)
      new(persona_autorizada: persona_autorizada).call
    end

    def initialize(persona_autorizada:)
      @persona_autorizada = persona_autorizada
    end

    def call
      user = @persona_autorizada.user

      if user.nil?
        resultado_usuario = ProvisionarUsuario.call(persona_autorizada: @persona_autorizada)
        unless resultado_usuario.success?
          return auditar_fallo(
            Result.new(enviado: false, paso: nil, errors: resultado_usuario.errors)
          )
        end

        user = resultado_usuario.user
        @persona_autorizada.reload
      end

      if user.onboarding_completado?
        return auditar_fallo(
          Result.new(
            enviado: false,
            paso: nil,
            errors: ['El enrolamiento de esta persona ya está completo']
          )
        )
      end

      if user.requiere_verificacion_email?
        envio = EnviarVerificacionEmail.call(user: user)
        return auditar_resultado(build_result(envio, PASO_VERIFICACION))
      end

      envio = EnviarEstablecerPasswordEmail.call(user: user)
      auditar_resultado(build_result(envio, PASO_PASSWORD))
    end

    private

    def auditar_resultado(resultado)
      if resultado.success?
        Auditoria::RegistrarPersona.call(
          accion: Auditoria::Acciones::PERSONA_REENVIAR_ONBOARDING,
          persona: @persona_autorizada,
          metadata: { paso: resultado.paso, enviado: resultado.enviado }
        )
      else
        auditar_fallo(resultado)
      end
      resultado
    end

    def auditar_fallo(resultado)
      Auditoria::RegistrarPersona.call(
        accion: Auditoria::Acciones::PERSONA_REENVIAR_ONBOARDING,
        persona: @persona_autorizada,
        resultado: AuditEvent::RESULTADO_FALLO,
        mensaje: resultado.errors.join(', '),
        metadata: { paso: resultado.paso }
      )
      resultado
    end

    def build_result(envio, paso)
      if envio.success? || envio.enviado
        Result.new(enviado: true, paso: paso, errors: [])
      else
        Result.new(enviado: false, paso: paso, errors: envio.errors)
      end
    end
  end
end

# frozen_string_literal: true

module PersonasAutorizadas
  # Crea una persona autorizada, provisiona su usuario y dispara el correo de verificación.
  class Crear
    Result = Struct.new(
      :persona_autorizada,
      :errors,
      :onboarding_email_enviado,
      keyword_init: true
    ) do
      def success?
        errors.blank? && persona_autorizada&.persisted? && persona_autorizada.user_id.present?
      end
    end

    def self.call(attributes:, password: nil)
      new(attributes: attributes, password: password).call
    end

    def initialize(attributes:, password: nil)
      @attributes = attributes
      @password = password
    end

    def call
      persona = PersonaAutorizada.new(@attributes)
      onboarding_email_enviado = false

      PersonaAutorizada.transaction do
        persona.save!
        resultado = ProvisionarUsuario.call(persona_autorizada: persona, password: @password)
        unless resultado.success?
          persona.errors.add(:base, resultado.errors.join(', '))
          raise ActiveRecord::Rollback
        end
      end

      if persona.persisted? && persona.user_id.present?
        envio = EnviarVerificacionEmail.call(user: persona.user)
        onboarding_email_enviado = envio.enviado
      end

      if persona.persisted? && persona.user_id.present?
        resultado = Result.new(
          persona_autorizada: persona,
          errors: [],
          onboarding_email_enviado: onboarding_email_enviado
        )
        auditar_exito(resultado)
        resultado
      else
        resultado = Result.new(
          persona_autorizada: persona,
          errors: persona.errors.full_messages,
          onboarding_email_enviado: false
        )
        auditar_fallo(resultado)
        resultado
      end
    rescue ActiveRecord::RecordInvalid => e
      auditar_fallo(
        Result.new(
          persona_autorizada: persona,
          errors: e.record.errors.full_messages,
          onboarding_email_enviado: false
        )
      )
    end

    private

    def auditar_exito(resultado)
      Auditoria::RegistrarPersona.call(
        accion: Auditoria::Acciones::PERSONA_CREAR,
        persona: resultado.persona_autorizada,
        metadata: { onboarding_email_enviado: resultado.onboarding_email_enviado }
      )
    end

    def auditar_fallo(resultado)
      Auditoria::RegistrarPersona.call(
        accion: Auditoria::Acciones::PERSONA_CREAR,
        persona: resultado.persona_autorizada,
        resultado: AuditEvent::RESULTADO_FALLO,
        mensaje: resultado.errors.join(', '),
        metadata: {
          rut: @attributes[:rut],
          email: @attributes[:email]
        }
      )
      resultado
    end
  end
end

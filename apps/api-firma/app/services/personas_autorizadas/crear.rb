# frozen_string_literal: true

module PersonasAutorizadas
  # Crea una persona autorizada y provisiona su usuario de login en una transacción.
  class Crear
    Result = Struct.new(:persona_autorizada, :errors, keyword_init: true) do
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

      PersonaAutorizada.transaction do
        persona.save!
        resultado = ProvisionarUsuario.call(persona_autorizada: persona, password: @password)
        unless resultado.success?
          persona.errors.add(:base, resultado.errors.join(', '))
          raise ActiveRecord::Rollback
        end
      end

      if persona.persisted? && persona.user_id.present?
        Result.new(persona_autorizada: persona, errors: [])
      else
        Result.new(persona_autorizada: persona, errors: persona.errors.full_messages)
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(persona_autorizada: persona, errors: e.record.errors.full_messages)
    end
  end
end

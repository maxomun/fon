# frozen_string_literal: true

module PersonasAutorizadas
  # Crea una persona autorizada, provisiona su usuario y la asigna a una empresa.
  class CrearYAsignar
    Result = Struct.new(
      :persona_autorizada,
      :asignacion,
      :errors,
      :onboarding_email_enviado,
      keyword_init: true
    ) do
      def success?
        errors.blank? && persona_autorizada&.persisted? && asignacion&.persisted?
      end
    end

    def self.call(empresa:, attributes:, es_administrador_empresa: false, password: nil)
      new(
        empresa: empresa,
        attributes: attributes,
        es_administrador_empresa: es_administrador_empresa,
        password: password
      ).call
    end

    def initialize(empresa:, attributes:, es_administrador_empresa: false, password: nil)
      @empresa = empresa
      @attributes = attributes
      @es_administrador_empresa = es_administrador_empresa
      @password = password
    end

    def call
      resultado_crear = Crear.call(attributes: @attributes, password: @password)
      unless resultado_crear.success?
        return Result.new(
          persona_autorizada: resultado_crear.persona_autorizada,
          asignacion: nil,
          errors: resultado_crear.errors,
          onboarding_email_enviado: false
        )
      end

      persona = resultado_crear.persona_autorizada
      asignacion = @empresa.empresa_personas_autorizadas.build(
        persona_autorizada: persona,
        es_administrador_empresa: @es_administrador_empresa
      )

      unless asignacion.save
        return Result.new(
          persona_autorizada: persona,
          asignacion: asignacion,
          errors: asignacion.errors.full_messages,
          onboarding_email_enviado: resultado_crear.onboarding_email_enviado
        )
      end

      Result.new(
        persona_autorizada: persona,
        asignacion: asignacion,
        errors: [],
        onboarding_email_enviado: resultado_crear.onboarding_email_enviado
      )
    end
  end
end

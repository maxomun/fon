# frozen_string_literal: true

module Certificados
  # Resuelve el certificado digital que debe usarse para firmar DTEs de una empresa.
  #
  # Reglas:
  # - La persona debe estar vinculada a la empresa y activa.
  # - Sin persona explícita: recorre personas_autorizadas por orden ASC, luego id.
  # - El certificado debe estar vigente, completo (crt + key) y no caducado.
  #
  # Ejemplo:
  #   resultado = Certificados::ResolverParaEmpresa.call(empresa_id: 1)
  #   resultado.certificado # => Certificado o nil
  #
  class ResolverParaEmpresa
    Result = Struct.new(:certificado, :persona_autorizada, :error, keyword_init: true) do
      def success?
        certificado.present? && error.nil?
      end
    end

    def self.call(empresa_id:, persona_autorizada_id: nil, user_id: nil)
      new(
        empresa_id: empresa_id,
        persona_autorizada_id: persona_autorizada_id,
        user_id: user_id
      ).call
    end

    def self.certificado_vigente_de(persona_autorizada)
      persona_autorizada
        .certificados
        .vigentes
        .order(fecha_adjuncion: :desc)
        .detect { |certificado| certificado_utilizable?(certificado) }
    end

    def self.certificado_utilizable?(certificado)
      certificado.completo? && !certificado.caducado?
    end

    def initialize(empresa_id:, persona_autorizada_id: nil, user_id: nil)
      @empresa_id = empresa_id
      @persona_autorizada_id = persona_autorizada_id
      @user_id = user_id
    end

    def call
      empresa = Empresa.find_by(id: @empresa_id)
      return failure('Empresa no encontrada') unless empresa

      if @persona_autorizada_id.present?
        resolve_for_persona(empresa, @persona_autorizada_id)
      elsif @user_id.present?
        resolve_for_user(empresa, @user_id)
      else
        resolve_by_prioridad(empresa)
      end
    end

    private

    def resolve_by_prioridad(empresa)
      empresa
        .personas_autorizadas
        .activas
        .por_prioridad
        .each do |persona|
          resultado = certificado_de_persona(persona)
          return resultado if resultado.success?
        end

      failure('La empresa no tiene certificado vigente para firmar')
    end

    def resolve_for_persona(empresa, persona_autorizada_id)
      persona = empresa
        .personas_autorizadas
        .activas
        .find_by(id: persona_autorizada_id)

      return failure('Persona autorizada no encontrada o inactiva para esta empresa') unless persona

      certificado = self.class.certificado_vigente_de(persona)
      return failure('La persona autorizada no tiene certificado vigente para firmar') unless certificado

      success(certificado, persona)
    end

    def resolve_for_user(empresa, user_id)
      persona = empresa
        .personas_autorizadas
        .activas
        .find_by(user_id: user_id)

      return failure('El usuario no tiene persona autorizada activa en esta empresa') unless persona

      certificado = self.class.certificado_vigente_de(persona)
      return failure('La persona autorizada del usuario no tiene certificado vigente para firmar') unless certificado

      success(certificado, persona)
    end

    def certificado_de_persona(persona)
      certificado = self.class.certificado_vigente_de(persona)
      return success(certificado, persona) if certificado

      failure('La persona autorizada no tiene certificado vigente para firmar')
    end

    def success(certificado, persona_autorizada)
      Result.new(certificado: certificado, persona_autorizada: persona_autorizada, error: nil)
    end

    def failure(message)
      Result.new(certificado: nil, persona_autorizada: nil, error: message)
    end
  end
end

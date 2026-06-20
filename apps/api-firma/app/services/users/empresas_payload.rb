# frozen_string_literal: true

module Users
  class EmpresasPayload
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      @user.empresas_asignadas.map { |empresa| empresa_resumen(empresa) }
    end

    private

    def empresa_resumen(empresa)
      asignacion = @user.persona_autorizada&.asignacion_en(empresa.id)

      {
        id: empresa.id,
        rut: empresa.rut,
        razon_social: empresa.razon_social,
        es_administrador: @user.administrador_fon? || asignacion&.es_administrador_empresa || false,
        puede_firmar: puede_firmar_en?(empresa.id)
      }
    end

    def puede_firmar_en?(empresa_id)
      return false if @user.administrador_fon?
      return false unless @user.persona_autorizada&.activa?

      Certificados::ResolverParaEmpresa.call(
        empresa_id: empresa_id,
        persona_autorizada_id: @user.persona_autorizada.id
      ).success?
    end
  end
end

# frozen_string_literal: true

module Auditoria
  class RegistrarPersona
    def self.call(accion:, persona: nil, empresa: nil, actor: nil, resultado: AuditEvent::RESULTADO_EXITO, cambios: {}, metadata: {}, codigo_error: nil, mensaje: nil)
      Registrar.call(
        accion: accion,
        categoria: Acciones::CATEGORIA_PERSONAS,
        actor: actor,
        empresa: empresa,
        recurso: persona,
        resultado: resultado,
        cambios: cambios,
        metadata: metadata,
        codigo_error: codigo_error,
        mensaje: mensaje
      )
    end
  end
end

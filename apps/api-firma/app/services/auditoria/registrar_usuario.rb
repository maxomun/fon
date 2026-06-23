# frozen_string_literal: true

module Auditoria
  class RegistrarUsuario
    def self.call(accion:, user: nil, actor: nil, resultado: AuditEvent::RESULTADO_EXITO, cambios: {}, metadata: {}, codigo_error: nil, mensaje: nil)
      Registrar.call(
        accion: accion,
        categoria: Acciones::CATEGORIA_USUARIOS,
        actor: actor,
        empresa: nil,
        recurso: user,
        resultado: resultado,
        cambios: cambios,
        metadata: metadata,
        codigo_error: codigo_error,
        mensaje: mensaje
      )
    end
  end
end

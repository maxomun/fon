# frozen_string_literal: true

module AuditableAuth
  extend ActiveSupport::Concern

  private

  def audit_auth_event(
    accion,
    actor: nil,
    recurso: nil,
    recurso_label: nil,
    resultado: AuditEvent::RESULTADO_EXITO,
    metadata: {},
    codigo_error: nil,
    mensaje: nil
  )
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_AUTH,
      actor: actor,
      recurso: recurso,
      recurso_label: recurso_label,
      resultado: resultado,
      metadata: metadata,
      codigo_error: codigo_error,
      mensaje: mensaje
    )
  end

  def audit_acceso_denegado!(codigo:, mensaje:)
    audit_auth_event(
      Auditoria::Acciones::AUTH_ACCESO_DENEGADO,
      actor: current_user,
      resultado: AuditEvent::RESULTADO_FALLO,
      metadata: {
        controller: controller_name,
        action: action_name,
        codigo: codigo
      },
      codigo_error: codigo,
      mensaje: mensaje
    )
  end
end

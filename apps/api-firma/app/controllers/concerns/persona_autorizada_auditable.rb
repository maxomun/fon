# frozen_string_literal: true

module PersonaAutorizadaAuditable
  extend ActiveSupport::Concern

  private

  def auditar_persona_actualizar(persona:, empresa: nil, onboarding_email_enviado: false, cambios: nil)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_ACTUALIZAR,
      persona: persona,
      empresa: empresa,
      cambios: cambios || Auditoria::Cambios.desde_modelo(persona),
      metadata: { onboarding_email_enviado: onboarding_email_enviado }
    )
  end

  def auditar_persona_actualizar_fallo(persona:, empresa: nil, mensaje:)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_ACTUALIZAR,
      persona: persona,
      empresa: empresa,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje
    )
  end

  def auditar_persona_eliminar(persona:)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_ELIMINAR,
      persona: persona,
      metadata: {
        rut: persona.rut,
        email: persona.email,
        nombre_completo: persona.nombre_completo
      }
    )
  end

  def auditar_persona_eliminar_fallo(persona:, mensaje:)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_ELIMINAR,
      persona: persona,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje
    )
  end

  def auditar_persona_asignar_empresa(persona:, empresa:, es_administrador_empresa:, origen:)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_ASIGNAR_EMPRESA,
      persona: persona,
      empresa: empresa,
      metadata: {
        es_administrador_empresa: es_administrador_empresa,
        origen: origen
      }
    )
  end

  def auditar_persona_quitar_empresa(persona:, empresa:)
    Auditoria::RegistrarPersona.call(
      accion: Auditoria::Acciones::PERSONA_QUITAR_EMPRESA,
      persona: persona,
      empresa: empresa
    )
  end

  def auditar_persona_admin_empresa(persona:, empresa:, valor_anterior:, valor_nuevo:)
    return if valor_anterior == valor_nuevo

    accion = valor_nuevo ? Auditoria::Acciones::PERSONA_ADMIN_EMPRESA_OTORGAR : Auditoria::Acciones::PERSONA_ADMIN_EMPRESA_QUITAR

    Auditoria::RegistrarPersona.call(
      accion: accion,
      persona: persona,
      empresa: empresa,
      cambios: { 'es_administrador_empresa' => [valor_anterior, valor_nuevo] }
    )
  end
end

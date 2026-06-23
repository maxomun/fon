# frozen_string_literal: true

module EmpresaConfigAuditable
  extend ActiveSupport::Concern

  private

  def auditar_evento_empresa(accion:, recurso:, empresa:, cambios: {}, metadata: {}, resultado: AuditEvent::RESULTADO_EXITO, mensaje: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_EMPRESA,
      recurso: recurso,
      empresa: empresa,
      cambios: cambios,
      metadata: metadata,
      resultado: resultado,
      mensaje: mensaje
    )
  end

  def auditar_evento_empresa_fallo(accion:, recurso:, empresa:, mensaje:, metadata: {})
    auditar_evento_empresa(
      accion: accion,
      recurso: recurso,
      empresa: empresa,
      metadata: metadata,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje
    )
  end

  def auditar_evento_certificado(accion:, recurso:, empresa: nil, metadata: {}, cambios: {}, resultado: AuditEvent::RESULTADO_EXITO, mensaje: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_CERTIFICADOS,
      recurso: recurso,
      empresa: empresa,
      metadata: metadata,
      cambios: cambios,
      resultado: resultado,
      mensaje: mensaje
    )
  end

  def auditar_evento_folio(accion:, recurso:, empresa:, metadata: {}, cambios: {}, resultado: AuditEvent::RESULTADO_EXITO, mensaje: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_FOLIOS,
      recurso: recurso,
      empresa: empresa,
      metadata: metadata,
      cambios: cambios,
      resultado: resultado,
      mensaje: mensaje
    )
  end

  def auditar_evento_catalogo(accion:, recurso:, cambios: {}, metadata: {}, resultado: AuditEvent::RESULTADO_EXITO, mensaje: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_CATALOGO,
      recurso: recurso,
      cambios: cambios,
      metadata: metadata,
      resultado: resultado,
      mensaje: mensaje
    )
  end

  def auditar_evento_catalogo_fallo(accion:, recurso:, mensaje:, metadata: {})
    auditar_evento_catalogo(
      accion: accion,
      recurso: recurso,
      metadata: metadata,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje
    )
  end
end

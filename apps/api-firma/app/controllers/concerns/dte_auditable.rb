# frozen_string_literal: true

module DteAuditable
  extend ActiveSupport::Concern

  private

  def auditar_dte(accion:, empresa:, resultado: AuditEvent::RESULTADO_EXITO, metadata: {}, recurso: nil, recurso_label: nil, mensaje: nil, codigo_error: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_DTE,
      actor: auditoria_actor_dte,
      empresa: empresa,
      recurso: recurso,
      recurso_label: recurso_label,
      metadata: metadata,
      resultado: resultado,
      mensaje: mensaje&.truncate(500),
      codigo_error: codigo_error
    )
  end

  def auditar_dte_fallo(accion:, mensaje: nil, empresa: nil, metadata: {}, codigo_error: nil)
    auditar_dte(
      accion: accion,
      empresa: empresa || empresa_auditoria_dte,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje,
      metadata: metadata,
      codigo_error: codigo_error
    )
  end

  def auditoria_actor_dte
    return current_user if respond_to?(:current_user, true) && current_user.present?

    Auditoria::Contexto.actor
  end

  def empresa_auditoria_dte
    return @empresa_auditoria_dte if defined?(@empresa_auditoria_dte) && @empresa_auditoria_dte.present?

    Empresa.find_by(id: params[:empresa_id]) if params[:empresa_id].present?
  end

  def metadata_dte_emision(empresa:, folios: nil, total_items: nil, total_paginas: nil, **extra)
    {
      tipo_documento: params[:tipo_documento].to_s,
      rut_receptor: rut_receptor_auditoria,
      folios: folios,
      total_items: total_items,
      total_paginas: total_paginas,
      empresa_rut: empresa&.rut
    }.merge(extra).compact
  end

  def rut_receptor_auditoria
    rec = params[:receptor]
    return nil unless rec

    rec[:rut] || rec['rut']
  end

  def etiqueta_recurso_dte(folios:)
    tipo = params[:tipo_documento].to_s
    folios_texto = Array(folios).join(', ')
    "DTE #{tipo} folio(s) #{folios_texto}"
  end

  def metadata_dte_emision_completa(resultado, resultado_persistencia: nil, resultado_envio: nil)
    metadata = metadata_dte_emision(
      empresa: resultado[:empresa],
      folios: resultado[:resultado_folios][:folios_usados],
      total_items: resultado[:items_array].count,
      total_paginas: resultado[:resultado_folios][:paginas].count,
      certificado_id: resultado[:certificado]&.id,
      persona_autorizada_id: resultado[:persona_autorizada]&.id
    )

    if resultado_persistencia
      metadata[:documento_emitido_ids] = resultado_persistencia[:documentos].map(&:id)
    end

    if resultado_envio
      metadata[:envio_sii] = resultado_envio_json(resultado_envio)
    end

    metadata
  end
end

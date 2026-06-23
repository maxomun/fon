# frozen_string_literal: true

module ProductoAuditable
  extend ActiveSupport::Concern

  CAMPOS_AUDITORIA_PRODUCTO = %w[codigo nombre precio_unitario activo].freeze

  private

  def auditar_evento_producto(accion:, recurso:, empresa:, cambios: {}, metadata: {}, resultado: AuditEvent::RESULTADO_EXITO, mensaje: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_PRODUCTOS,
      recurso: recurso,
      recurso_label: etiqueta_producto(recurso),
      empresa: empresa,
      cambios: cambios,
      metadata: metadata,
      resultado: resultado,
      mensaje: mensaje
    )
  end

  def auditar_evento_producto_fallo(accion:, recurso:, empresa:, mensaje:, metadata: {}, codigo_error: nil)
    Auditoria::Registrar.call(
      accion: accion,
      categoria: Auditoria::Acciones::CATEGORIA_PRODUCTOS,
      recurso: recurso,
      recurso_label: etiqueta_producto(recurso),
      empresa: empresa,
      metadata: metadata,
      resultado: AuditEvent::RESULTADO_FALLO,
      mensaje: mensaje,
      codigo_error: codigo_error
    )
  end

  def metadata_producto(producto)
    {
      codigo: producto.codigo,
      nombre: producto.nombre,
      precio_unitario: producto.precio_unitario,
      activo: producto.activo,
      impuesto_ids: producto.impuesto_ids
    }
  end

  def cambios_producto(producto, impuestos_extra: nil)
    cambios = Auditoria::Cambios.desde_modelo(producto, solo: CAMPOS_AUDITORIA_PRODUCTO)
    cambios = cambios.except('fecha_creacion', 'fecha_actualizacion')
    cambios.merge!(impuestos_extra) if impuestos_extra.present?
    cambios
  end

  def etiqueta_producto(producto)
    return nil if producto.nil?

    codigo = producto.try(:codigo)
    nombre = producto.try(:nombre)
    return "#{codigo} — #{nombre}" if codigo.present? && nombre.present?
    return codigo if codigo.present?

    nombre
  end
end

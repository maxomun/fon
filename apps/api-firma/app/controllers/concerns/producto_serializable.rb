# frozen_string_literal: true

module ProductoSerializable
  extend ActiveSupport::Concern

  private

  def producto_payload(producto, detalle: false)
    payload = {
      id: producto.id,
      empresa_id: producto.empresa_id,
      codigo: producto.codigo,
      nombre: producto.nombre,
      precio_unitario: format('%.2f', producto.precio_unitario),
      precio_con_impuestos: format('%.2f', producto.precio_con_impuestos),
      activo: producto.activo,
      ambito_monto: producto.read_attribute(:ambito_monto),
      ambito_monto_efectivo: producto.ambito_monto_efectivo,
      afecto: producto.afecto?,
      impuestos: impuestos_producto_payload(producto),
      tiene_ventas: producto.tiene_ventas?,
      fecha_creacion: producto.fecha_creacion,
      fecha_actualizacion: producto.fecha_actualizacion
    }

    return payload unless detalle

    payload
  end

  def impuestos_producto_payload(producto)
    producto.impuestos.map do |impuesto|
      {
        id: impuesto.id,
        abreviacion: impuesto.abreviacion,
        nombre: impuesto.nombre,
        tasa_vigente: impuesto.valor_vigente
      }
    end
  end

  def impuesto_disponible_payload(impuesto)
    {
      id: impuesto.id,
      abreviacion: impuesto.abreviacion,
      nombre: impuesto.nombre,
      tasa_vigente: impuesto.valor_vigente
    }
  end

  def render_producto_validation_error(record, message: 'Error de validación')
    render_error(
      message,
      :unprocessable_entity,
      code: 'VALIDATION_ERROR',
      errors: record.errors.full_messages
    )
  end
end

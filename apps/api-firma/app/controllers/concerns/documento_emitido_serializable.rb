# frozen_string_literal: true

module DocumentoEmitidoSerializable
  extend ActiveSupport::Concern

  private

  def documento_emitido_list_payload(documento)
    {
      id: documento.id,
      folio: documento.folio,
      tipo_documento: documento.tipo_documento_codigo,
      tipo_documento_nombre: documento.tipo_habilitado.tipo_documento.nombre,
      rut_receptor: documento.rut_receptor,
      razon_social_receptor: documento.razon_social_receptor,
      total: format('%.2f', documento.total),
      dte_envio_id: documento.dte_envio_id,
      xml_disponible: documento.dte_envio&.xml_firmado&.attached? || false,
      pdf_disponible: documento.pdf.attached?,
      emitido_at: documento.dte_envio&.created_at&.iso8601,
      usuario_email: documento.usuario&.email
    }
  end

  def documento_emitido_detail_payload(documento)
    documento_emitido_list_payload(documento).merge(
      rut_emisor: documento.rut_emisor,
      razon_social_emisor: documento.razon_social_emisor,
      giro_receptor: documento.giro_receptor,
      direccion_receptor: documento.direccion_receptor,
      fecha_emision: Dte::Referencias::DocumentoOrigen.fecha_emision(documento)&.iso8601,
      lineas: documento.venta_detalles.sort_by(&:item).map { |linea| venta_detalle_payload(linea) },
      descuentos_recargos_globales: documento.documento_descuentos_recargos_globales.ordenados.map do |movimiento|
        documento_descuento_recargo_global_payload(movimiento)
      end,
      referencias: documento.documento_emitido_referencias.ordenados.map do |referencia|
        documento_emitido_referencia_payload(referencia)
      end
    )
  end

  def documento_emitido_referencia_payload(referencia)
    {
      nro_linea: referencia.nro_linea,
      orden: referencia.orden,
      tipo_documento_referencia: referencia.tipo_referencia_documento.codigo_sii,
      tipo_documento_referencia_nombre: referencia.tipo_referencia_documento.nombre,
      folio_referencia: referencia.folio_referencia,
      fecha_referencia: referencia.fecha_referencia.iso8601,
      codigo_referencia: referencia.codigo_referencia,
      razon_referencia: referencia.razon_referencia,
      documento_emitido_origen_id: referencia.documento_emitido_origen_id
    }
  end

  def documento_descuento_recargo_global_payload(movimiento)
    {
      nro_linea: movimiento.nro_linea,
      tipo_movimiento: movimiento.tipo_movimiento,
      glosa: movimiento.glosa,
      tipo_valor: movimiento.tipo_valor,
      valor: movimiento.valor.to_f,
      aplica_sobre: movimiento.aplica_sobre,
      monto_calculado: movimiento.monto_calculado,
      orden: movimiento.orden
    }
  end

  def venta_detalle_payload(linea)
    {
      item: linea.item,
      cantidad: linea.cantidad.to_f,
      precio_unitario: format('%.2f', linea.precio_unitario),
      descuento: linea.descuento.to_f,
      afecto: linea.afecto,
      ambito_monto: linea.ambito_monto,
      impuesto: linea.impuesto.to_f,
      subtotal_con_impuesto: format('%.2f', linea.subtotal_con_impuesto)
    }
  end

  def documento_para_referencia_payload(documento, referencias_uso = [])
    fecha = Dte::Referencias::DocumentoOrigen.fecha_emision(documento)

    {
      id: documento.id,
      folio: documento.folio,
      tipo_documento: documento.tipo_documento_codigo,
      tipo_documento_nombre: documento.tipo_habilitado.tipo_documento.nombre,
      fecha_emision: fecha&.iso8601,
      rut_receptor: documento.rut_receptor,
      razon_social_receptor: documento.razon_social_receptor,
      total: format('%.2f', documento.total),
      referenciado_en: Array(referencias_uso).map { |referencia| referencia_uso_payload(referencia) }
    }
  end

  def referencia_uso_payload(referencia)
    documento = referencia.documento_emitido

    {
      documento_emitido_id: documento.id,
      folio: documento.folio,
      tipo_documento: documento.tipo_documento_codigo,
      tipo_documento_nombre: documento.tipo_habilitado.tipo_documento.nombre
    }
  end
end

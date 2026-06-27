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
      lineas: documento.venta_detalles.sort_by(&:item).map { |linea| venta_detalle_payload(linea) }
    )
  end

  def venta_detalle_payload(linea)
    {
      item: linea.item,
      cantidad: linea.cantidad.to_f,
      precio_unitario: format('%.2f', linea.precio_unitario),
      descuento: linea.descuento.to_f,
      afecto: linea.afecto,
      impuesto: linea.impuesto.to_f,
      subtotal_con_impuesto: format('%.2f', linea.subtotal_con_impuesto)
    }
  end
end

# frozen_string_literal: true

module TipoReferenciaDocumentoSerializable
  extend ActiveSupport::Concern

  private

  def tipo_referencia_documento_payload(tipo_referencia)
    {
      id: tipo_referencia.id,
      codigo_sii: tipo_referencia.codigo_sii,
      nombre: tipo_referencia.nombre,
      categoria: tipo_referencia.categoria,
      requiere_folio: tipo_referencia.requiere_folio,
      requiere_fecha: tipo_referencia.requiere_fecha,
      permite_codigo_referencia: tipo_referencia.permite_codigo_referencia,
      observacion: tipo_referencia.observacion
    }
  end
end

# frozen_string_literal: true

module TipoDocumentoSerializable
  extend ActiveSupport::Concern

  private

  def tipo_documento_payload(tipo_documento)
    {
      id: tipo_documento.id,
      codigo: tipo_documento.codigo,
      nombre: tipo_documento.nombre,
      dte: tipo_documento.dte,
      manual: tipo_documento.manual
    }
  end
end

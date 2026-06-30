# frozen_string_literal: true

module Dte
  module Referencias
    module Constants
      MAX_REFERENCIAS = 40
      CODIGOS_REFERENCIA = (1..4).freeze
      MAX_FOLIO = 18
      MAX_RAZON = 90

      CAMPOS_REQUERIDOS = %i[
        tipo_documento_referencia
        folio_referencia
        fecha_referencia
      ].freeze

      ALIAS_CAMPOS = {
        tipo_documento_referencia: %i[tpo_doc_ref tipo_documento_referencia],
        folio_referencia: %i[folio_ref folio_referencia],
        fecha_referencia: %i[fch_ref fecha_referencia],
        codigo_referencia: %i[cod_ref codigo_referencia],
        razon_referencia: %i[razon_ref razon_referencia],
        documento_emitido_origen_id: %i[documento_emitido_origen_id]
      }.freeze
    end
  end
end

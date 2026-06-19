# frozen_string_literal: true

module TipoHabilitadoSerializable
  extend ActiveSupport::Concern

  private

  def tipo_habilitado_payload(tipo_habilitado)
    {
      id: tipo_habilitado.id,
      empresa_id: tipo_habilitado.empresa_id,
      tipo_documento: {
        id: tipo_habilitado.tipo_documento.id,
        codigo: tipo_habilitado.tipo_documento.codigo,
        nombre: tipo_habilitado.tipo_documento.nombre,
        dte: tipo_habilitado.tipo_documento.dte
      },
      fecha_habilitacion: tipo_habilitado.fecha_habilitacion,
      tiene_rangos_folio: tipo_habilitado.tiene_rangos_folio?,
      tiene_documentos_emitidos: tipo_habilitado.tiene_documentos_emitidos?,
      folios_disponibles: tipo_habilitado.folios_disponibles_count
    }
  end

  def render_tipo_habilitado_validation_error(record)
    render_error(
      'Error de validación',
      :unprocessable_entity,
      code: 'VALIDATION_ERROR',
      errors: record.errors.full_messages
    )
  end
end

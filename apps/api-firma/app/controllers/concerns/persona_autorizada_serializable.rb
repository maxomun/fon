# frozen_string_literal: true

module PersonaAutorizadaSerializable
  extend ActiveSupport::Concern

  private

  def persona_autorizada_payload(persona, include_empresas: false)
    certificado = persona.certificado_vigente

    payload = {
      id: persona.id,
      rut: persona.rut,
      nombres: persona.nombres,
      apellido_paterno: persona.apellido_paterno,
      apellido_materno: persona.apellido_materno,
      nombre_completo: persona.nombre_completo,
      email: persona.email,
      estado: persona.estado,
      activa: persona.activa?,
      orden: persona.orden,
      user_id: persona.user_id,
      fecha_creacion: persona.fecha_creacion,
      fecha_actualizacion: persona.fecha_actualizacion,
      certificado_vigente_id: certificado&.id,
      tiene_certificado_vigente: certificado.present?,
      puede_eliminarse: persona.puede_eliminarse?
    }

    if include_empresas
      payload[:empresas] = persona.empresas.order(:razon_social).map do |empresa|
        {
          id: empresa.id,
          rut: empresa.rut,
          razon_social: empresa.razon_social
        }
      end
    end

    payload
  end

  def persona_autorizada_asignada_payload(persona, asignacion: nil)
    persona_autorizada_payload(persona).merge(
      fecha_asignacion: asignacion&.fecha_creacion,
      es_administrador_empresa: asignacion&.es_administrador_empresa || false
    )
  end

  def render_persona_validation_error(record)
    render_error(
      'Error de validación',
      :unprocessable_entity,
      code: 'VALIDATION_ERROR',
      errors: record.errors.full_messages
    )
  end
end

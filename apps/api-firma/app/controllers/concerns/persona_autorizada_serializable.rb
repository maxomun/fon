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
    }.merge(onboarding_payload_for(persona.user))

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

  def onboarding_payload_for(user)
    return onboarding_payload_vacio unless user

    {
      email_verificado: user.email_verificado?,
      onboarding_completado: user.onboarding_completado?,
      requiere_verificacion_email: user.requiere_verificacion_email?,
      requiere_onboarding: user.requiere_onboarding?,
      debe_cambiar_password: user.debe_cambiar_password
    }
  end

  def onboarding_payload_vacio
    {
      email_verificado: false,
      onboarding_completado: false,
      requiere_verificacion_email: false,
      requiere_onboarding: false,
      debe_cambiar_password: false
    }
  end

  def mensaje_onboarding(onboarding_email_enviado:, accion:)
    case accion
    when :creada
      base = 'Persona autorizada creada exitosamente'
    when :asignada
      base = 'Persona autorizada asignada a la empresa exitosamente'
    when :creada_y_asignada
      base = 'Persona autorizada creada y asignada a la empresa exitosamente'
    when :actualizada
      base = 'Persona autorizada actualizada exitosamente'
    else
      base = 'Operación completada exitosamente'
    end

    return "#{base}. Se envió un correo de verificación." if onboarding_email_enviado

    base
  end

  def mensaje_reenvio_onboarding(paso:)
    case paso
    when PersonasAutorizadas::ReenviarOnboarding::PASO_PASSWORD
      'Se reenvió el correo para establecer contraseña.'
    else
      'Se reenvió el correo de verificación.'
    end
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

# frozen_string_literal: true

module Auditoria
  class Payload
    def self.collection(eventos)
      eventos.map { |evento| evento(evento) }
    end

    def self.evento(evento, detalle: false)
      payload = {
        id: evento.id,
        accion: evento.accion,
        accion_label: Acciones.etiqueta(evento.accion),
        categoria: evento.categoria,
        resultado: evento.resultado,
        actor: actor(evento),
        empresa: empresa(evento),
        recurso: recurso(evento),
        created_at: evento.created_at.iso8601
      }

      return payload unless detalle

      payload.merge(
        cambios: evento.cambios || {},
        metadata: evento.metadata || {},
        codigo_error: evento.codigo_error,
        mensaje: evento.mensaje,
        ip: evento.ip,
        user_agent: evento.user_agent,
        request_id: evento.request_id
      )
    end

    def self.actor(evento)
      {
        user_id: evento.actor_user_id,
        email: evento.actor_email,
        nombre: evento.actor_nombre,
        acceso_global: evento.actor_acceso_global
      }
    end

    def self.empresa(evento)
      return nil if evento.empresa_id.blank?

      emp = evento.empresa
      return { id: evento.empresa_id } unless emp

      {
        id: emp.id,
        rut: emp.rut,
        razon_social: emp.razon_social
      }
    end

    def self.recurso(evento)
      return nil if evento.recurso_tipo.blank? && evento.recurso_label.blank?

      {
        tipo: evento.recurso_tipo,
        id: evento.recurso_id,
        label: evento.recurso_label
      }
    end
  end
end

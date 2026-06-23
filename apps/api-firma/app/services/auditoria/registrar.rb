# frozen_string_literal: true

module Auditoria
  class Registrar
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(
      accion:,
      categoria:,
      actor: nil,
      empresa: nil,
      recurso: nil,
      recurso_label: nil,
      resultado: AuditEvent::RESULTADO_EXITO,
      cambios: {},
      metadata: {},
      codigo_error: nil,
      mensaje: nil,
      request: nil
    )
      @accion = accion
      @categoria = categoria
      @actor = actor || Auditoria::Contexto.actor
      @empresa = empresa
      @recurso = recurso
      @recurso_label = recurso_label
      @resultado = normalizar_resultado(resultado)
      @cambios = cambios
      @metadata = metadata
      @codigo_error = codigo_error
      @mensaje = mensaje
      @request = request
    end

    def call
      AuditEvent.create!(atributos_evento)
    rescue StandardError => e
      Rails.logger.error("[auditoria] No se pudo registrar #{@accion}: #{e.class}: #{e.message}")
      nil
    end

    private

    def atributos_evento
      actor_attrs = atributos_actor
      recurso_attrs = atributos_recurso

      {
        accion: @accion,
        categoria: @categoria,
        resultado: @resultado,
        actor_user_id: actor_attrs[:actor_user_id],
        actor_email: actor_attrs[:actor_email],
        actor_nombre: actor_attrs[:actor_nombre],
        actor_acceso_global: actor_attrs[:actor_acceso_global],
        empresa_id: resolver_empresa_id,
        recurso_tipo: recurso_attrs[:recurso_tipo],
        recurso_id: recurso_attrs[:recurso_id],
        recurso_label: recurso_attrs[:recurso_label],
        cambios: SanitizarCambios.call(@cambios || {}),
        metadata: SanitizarCambios.call(@metadata || {}),
        codigo_error: @codigo_error,
        mensaje: @mensaje&.truncate(500),
        ip: contexto.ip,
        user_agent: contexto.user_agent,
        request_id: contexto.request_id
      }
    end

    def atributos_actor
      return actor_vacio unless @actor.is_a?(User)

      {
        actor_user_id: @actor.id,
        actor_email: @actor.email,
        actor_nombre: @actor.nombre_completo.presence || @actor.email,
        actor_acceso_global: @actor.administrador_fon?
      }
    end

    def actor_vacio
      {
        actor_user_id: nil,
        actor_email: nil,
        actor_nombre: nil,
        actor_acceso_global: nil
      }
    end

    def atributos_recurso
      return recurso_vacio if @recurso.nil?

      if @recurso.is_a?(ActiveRecord::Base)
        return {
          recurso_tipo: @recurso.class.name,
          recurso_id: @recurso.id.to_s,
          recurso_label: @recurso_label.presence || etiqueta_recurso(@recurso)
        }
      end

      if @recurso.is_a?(Hash)
        return {
          recurso_tipo: @recurso[:tipo] || @recurso['tipo'],
          recurso_id: (@recurso[:id] || @recurso['id']).to_s.presence,
          recurso_label: @recurso_label.presence || @recurso[:label] || @recurso['label']
        }
      end

      recurso_vacio
    end

    def recurso_vacio
      {
        recurso_tipo: nil,
        recurso_id: nil,
        recurso_label: @recurso_label
      }
    end

    def etiqueta_recurso(recurso)
      return recurso.email if recurso.respond_to?(:email) && recurso.email.present?
      return recurso.nombre_completo if recurso.respond_to?(:nombre_completo) && recurso.nombre_completo.present?

      "#{recurso.class.name}##{recurso.id}"
    end

    def resolver_empresa_id
      case @empresa
      when Empresa
        @empresa.id
      when Integer
        @empresa
      else
        nil
      end
    end

    def normalizar_resultado(resultado)
      case resultado.to_s
      when AuditEvent::RESULTADO_FALLO, 'fallo', 'false'
        AuditEvent::RESULTADO_FALLO
      else
        AuditEvent::RESULTADO_EXITO
      end
    end

    def contexto
      return contexto_request if @request.present?

      Auditoria::Contexto
    end

    def contexto_request
      @contexto_request ||= Struct.new(:ip, :user_agent, :request_id).new(
        @request.remote_ip,
        @request.user_agent&.truncate(500),
        @request.request_id
      )
    end
  end
end

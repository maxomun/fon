# frozen_string_literal: true

module Users
  # Payload de usuario para administración de plataforma (listado y detalle FON).
  class AdminPayload
    TIPO_PLATAFORMA = 'plataforma'
    TIPO_PERSONA_AUTORIZADA = 'persona_autorizada'

    def self.call(user, detalle: false)
      new(user, detalle: detalle).call
    end

    def initialize(user, detalle: false)
      @user = user
      @detalle = detalle
    end

    def call
      payload = base_payload.merge(estado_payload, roles: roles_payload)

      payload[:persona_autorizada] = persona_autorizada_payload if @detalle

      payload
    end

    private

    def base_payload
      {
        id: @user.id,
        email: @user.email,
        username: @user.username,
        lenguaje: @user.lenguaje,
        nombres: @user.nombres,
        apellido_paterno: @user.apellido_paterno,
        apellido_materno: @user.apellido_materno,
        nombre_completo: @user.nombre_completo.presence,
        visible: @user.visible,
        tipo_cuenta: tipo_cuenta,
        persona_autorizada_id: @user.persona_autorizada&.id,
        puede_editar: puede_editar?,
        acceso_global: @user.administrador_fon?,
        timestamp: @user.timestamp
      }
    end

    def estado_payload
      {
        estado: @user.estado,
        activo: @user.activo?,
        email_verificado: @user.email_verificado?,
        onboarding_completado: @user.onboarding_completado?,
        requiere_verificacion_email: @user.requiere_verificacion_email?,
        requiere_onboarding: @user.requiere_onboarding?,
        debe_cambiar_password: @user.debe_cambiar_password
      }
    end

    def roles_payload
      @user.roles.map do |rol|
        {
          codigo: rol.codigo,
          descripcion: rol.descripcion,
          esadmin: rol.esadmin
        }
      end
    end

    def persona_autorizada_payload
      persona = @user.persona_autorizada
      return nil unless persona

      {
        id: persona.id,
        rut: persona.rut,
        nombres: persona.nombres,
        apellido_paterno: persona.apellido_paterno,
        apellido_materno: persona.apellido_materno,
        nombre_completo: persona.nombre_completo,
        email: persona.email,
        activa: persona.activa?,
        empresas: persona.empresas.order(:razon_social).map do |empresa|
          asignacion = persona.asignacion_en(empresa.id)
          {
            id: empresa.id,
            rut: empresa.rut,
            razon_social: empresa.razon_social,
            es_administrador_empresa: asignacion&.es_administrador_empresa || false
          }
        end
      }
    end

    def tipo_cuenta
      @user.persona_autorizada.present? ? TIPO_PERSONA_AUTORIZADA : TIPO_PLATAFORMA
    end

    def puede_editar?
      @user.persona_autorizada.blank?
    end
  end
end

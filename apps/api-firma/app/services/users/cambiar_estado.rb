# frozen_string_literal: true

module Users
  class CambiarEstado
    Result = Struct.new(:user, :errors, keyword_init: true) do
      def success?
        errors.blank? && user.present?
      end
    end

    def self.call(user:, activo:, actor:)
      new(user: user, activo: activo, actor: actor).call
    end

    def initialize(user:, activo:, actor:)
      @user = user
      @activo = ActiveModel::Type::Boolean.new.cast(activo)
      @actor = actor
    end

    def call
      if @user.persona_autorizada.present?
        return auditar_fallo(failure(['Este usuario está vinculado a una persona autorizada']))
      end

      if !@activo && @user.id == @actor.id
        return auditar_fallo(failure(['No puede desactivar su propia cuenta']))
      end

      if !@activo && @user.administrador_fon? && GestionRolesFon.ultimo_administrador_fon_activo?(except_user: @user)
        return auditar_fallo(failure(['No puede desactivar al último administrador FON activo']))
      end

      estado_anterior = @user.estado
      @user.update!(estado: @activo ? User::ESTADO_ACTIVO : User::ESTADO_INACTIVO)
      @user.revocar_todas_las_sesiones! unless @activo

      resultado = Result.new(user: @user, errors: [])
      auditar_exito(resultado, estado_anterior: estado_anterior)
      resultado
    rescue ActiveRecord::RecordInvalid => e
      auditar_fallo(failure(e.record.errors.full_messages))
    end

    private

    def auditar_exito(resultado, estado_anterior:)
      accion = @activo ? Auditoria::Acciones::USUARIO_ACTIVAR : Auditoria::Acciones::USUARIO_DESACTIVAR

      Auditoria::RegistrarUsuario.call(
        accion: accion,
        user: resultado.user,
        actor: @actor,
        cambios: { 'estado' => [estado_anterior, resultado.user.estado] },
        metadata: { sesiones_revocadas: !@activo }
      )
    end

    def auditar_fallo(resultado)
      accion = @activo ? Auditoria::Acciones::USUARIO_ACTIVAR : Auditoria::Acciones::USUARIO_DESACTIVAR

      Auditoria::RegistrarUsuario.call(
        accion: accion,
        user: @user,
        actor: @actor,
        resultado: AuditEvent::RESULTADO_FALLO,
        mensaje: resultado.errors.join(', ')
      )
      resultado
    end

    def failure(errors)
      Result.new(user: @user, errors: Array(errors))
    end
  end
end

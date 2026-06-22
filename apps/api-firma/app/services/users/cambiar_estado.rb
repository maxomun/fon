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
      return failure(['Este usuario está vinculado a una persona autorizada']) if @user.persona_autorizada.present?

      if !@activo && @user.id == @actor.id
        return failure(['No puede desactivar su propia cuenta'])
      end

      if !@activo && @user.administrador_fon? && GestionRolesFon.ultimo_administrador_fon_activo?(except_user: @user)
        return failure(['No puede desactivar al último administrador FON activo'])
      end

      @user.update!(estado: @activo ? User::ESTADO_ACTIVO : User::ESTADO_INACTIVO)
      @user.revocar_todas_las_sesiones! unless @activo

      Result.new(user: @user, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def failure(errors)
      Result.new(user: @user, errors: Array(errors))
    end
  end
end

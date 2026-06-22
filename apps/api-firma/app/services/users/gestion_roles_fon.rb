# frozen_string_literal: true

module Users
  module GestionRolesFon
    module_function

    def asignar!(user)
      rol = rol_administrador_fon
      return if user.tiene_rol?(User::ROL_ADMINISTRADOR_FON)

      user.user_roles.create!(rol: rol)
    end

    def quitar!(user)
      return unless user.tiene_rol?(User::ROL_ADMINISTRADOR_FON)
      raise StandardError, 'No puede quitar el rol al último administrador FON activo' if ultimo_administrador_fon_activo?(except_user: user)

      user.user_roles.where(rol_id: rol_administrador_fon.id).destroy_all
    end

    def sincronizar!(user, asignar:)
      ActiveModel::Type::Boolean.new.cast(asignar) ? asignar!(user) : quitar!(user)
    end

    def ultimo_administrador_fon_activo?(except_user: nil)
      scope = User
        .activos
        .joins(:roles)
        .where(roles: { codigo: User::ROL_ADMINISTRADOR_FON })

      scope = scope.where.not(id: except_user.id) if except_user

      !scope.exists?
    end

    def rol_administrador_fon
      Rol.find_by!(codigo: User::ROL_ADMINISTRADOR_FON)
    end
  end
end

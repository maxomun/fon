# frozen_string_literal: true

class UserRol < ApplicationRecord
  self.table_name = 'user_roles'

  # Relaciones
  belongs_to :user
  belongs_to :rol, foreign_key: :rol_id

  # Validaciones
  validates :user_id, uniqueness: { scope: :rol_id, message: 'ya tiene este rol asignado' }
end

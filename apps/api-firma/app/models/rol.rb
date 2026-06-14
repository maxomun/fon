# frozen_string_literal: true

class Rol < ApplicationRecord
  self.table_name = 'roles'

  # Relaciones
  has_many :user_roles, class_name: 'UserRol', foreign_key: :rol_id, dependent: :destroy
  has_many :users, through: :user_roles

  # Validaciones
  validates :codigo, presence: true, length: { maximum: 100 }
  validates :descripcion, presence: true, length: { maximum: 200 }
  validates :esadmin, inclusion: { in: [true, false] }
end

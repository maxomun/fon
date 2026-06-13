# frozen_string_literal: true

class GrupoActeco < ApplicationRecord
  self.table_name = 'grupo_actecos'

  # Relaciones
  has_many :actecos, dependent: :restrict_with_error

  # Validaciones
  validates :nombre, presence: true, length: { maximum: 100 }
end

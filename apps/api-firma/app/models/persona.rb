# frozen_string_literal: true

class Persona < ApplicationRecord
  self.table_name = 'personas'

  # Relaciones
  belongs_to :user

  # Validaciones
  validates :user_id, uniqueness: true
  validates :nombres, presence: true, length: { maximum: 250 }
  validates :uid, length: { maximum: 100 }, allow_blank: true
  validates :apellido_paterno, length: { maximum: 250 }, allow_blank: true
  validates :apellido_materno, length: { maximum: 250 }, allow_blank: true

  # Métodos
  def nombre_completo
    [nombres, apellido_paterno, apellido_materno].compact.join(' ')
  end
end

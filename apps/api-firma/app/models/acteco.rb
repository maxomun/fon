# frozen_string_literal: true

class Acteco < ApplicationRecord
  self.table_name = 'actecos'

  # Relaciones
  belongs_to :grupo_acteco
  has_many :acteco_empresas, dependent: :destroy
  has_many :empresas, through: :acteco_empresas

  # Validaciones
  validates :codigo, presence: true, length: { maximum: 6 }
  validates :nombre, presence: true, length: { maximum: 100 }
  validates :afecto_iva, inclusion: { in: [true, false] }
  validates :categoria_tributaria, presence: true
  validates :disponible_internet, inclusion: { in: [true, false] }
end

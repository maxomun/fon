# frozen_string_literal: true

class Pais < ApplicationRecord
  self.table_name = 'paises'

  has_many :empresas, dependent: :restrict_with_error
  has_many :impuestos, dependent: :restrict_with_error

  validates :codigo, presence: true, length: { maximum: 3 }, uniqueness: true
  validates :nombre, presence: true, length: { maximum: 100 }
  validates :activo, inclusion: { in: [true, false] }

  scope :activos, -> { where(activo: true) }
end

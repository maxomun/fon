# frozen_string_literal: true

class Proveedor < ApplicationRecord
  self.table_name = 'proveedores'

  # Relaciones
  belongs_to :empresa
  has_many :documento_recibidos, dependent: :restrict_with_error

  # Validaciones
  validates :rut, presence: true, length: { maximum: 12 }, uniqueness: { scope: :empresa_id }
  validates :razon_social, presence: true, length: { maximum: 250 }
  validates :giro, presence: true, length: { maximum: 250 }
  validates :direccion, length: { maximum: 250 }, allow_blank: true
end

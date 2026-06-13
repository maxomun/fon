# frozen_string_literal: true

class Producto < ApplicationRecord
  self.table_name = 'productos'

  # Relaciones
  belongs_to :empresa
  has_many :producto_impuestos, dependent: :destroy
  has_many :impuestos, through: :producto_impuestos
  has_many :venta_detalles, dependent: :restrict_with_error

  # Validaciones
  validates :codigo, presence: true, length: { maximum: 50 }, uniqueness: { scope: :empresa_id }
  validates :nombre, presence: true, length: { maximum: 250 }
  validates :precio_unitario, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Métodos
  def afecto_iva?
    impuestos.exists?(abreviacion: 'IVA')
  end
end

# frozen_string_literal: true

class ProductoImpuesto < ApplicationRecord
  self.table_name = 'producto_impuestos'

  # Relaciones
  belongs_to :producto
  belongs_to :impuesto

  # Validaciones
  validates :impuesto_id, uniqueness: { scope: :producto_id, message: 'ya está asignado a este producto' }
end

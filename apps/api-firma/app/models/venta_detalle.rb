# frozen_string_literal: true

class VentaDetalle < ApplicationRecord
  self.table_name = 'venta_detalles'

  # Relaciones
  belongs_to :documento_emitido
  belongs_to :producto, optional: true

  # Validaciones
  validates :item, presence: true, length: { maximum: 250 }
  validates :cantidad, presence: true, numericality: { greater_than: 0 }
  validates :precio_unitario, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :descuento, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :afecto, inclusion: { in: [true, false] }
  validates :impuesto, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Métodos de cálculo
  def subtotal
    cantidad * precio_unitario
  end

  def monto_descuento
    subtotal * (descuento / 100.0)
  end

  def subtotal_con_descuento
    subtotal - monto_descuento
  end

  def monto_impuesto
    return 0 unless afecto

    subtotal_con_descuento * (impuesto / 100.0)
  end

  def subtotal_con_impuesto
    subtotal_con_descuento + monto_impuesto
  end
end

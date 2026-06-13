# frozen_string_literal: true

class Impuesto < ApplicationRecord
  self.table_name = 'impuestos'

  # Relaciones
  has_many :impuesto_valores, dependent: :destroy
  has_many :producto_impuestos, dependent: :destroy
  has_many :productos, through: :producto_impuestos

  # Validaciones
  validates :nombre, presence: true, length: { maximum: 200 }
  validates :abreviacion, presence: true, length: { maximum: 50 }

  # Métodos
  def valor_vigente
    impuesto_valores
      .where('fecha_activacion <= ?', Time.current)
      .where('fecha_caducacion IS NULL OR fecha_caducacion > ?', Time.current)
      .order(fecha_activacion: :desc)
      .first
      &.valor
  end
end

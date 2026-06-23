# frozen_string_literal: true

class Producto < ApplicationRecord
  self.table_name = 'productos'
  self.record_timestamps = false

  before_update :set_fecha_actualizacion

  # Relaciones
  belongs_to :empresa
  has_many :producto_impuestos, dependent: :destroy
  has_many :impuestos, through: :producto_impuestos
  has_many :venta_detalles, dependent: :restrict_with_error

  # Scopes
  scope :activos, -> { where(activo: true) }
  scope :inactivos, -> { where(activo: false) }

  # Validaciones
  validates :codigo, presence: true, length: { maximum: 50 }, uniqueness: { scope: :empresa_id }
  validates :nombre, presence: true, length: { maximum: 250 }
  validates :precio_unitario, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :activo, inclusion: { in: [true, false] }

  def afecto_iva?
    impuestos.exists?(abreviacion: 'IVA')
  end

  def afecto?
    producto_impuestos.exists?
  end

  def tiene_ventas?
    venta_detalles.exists?
  end

  def precio_con_impuestos
    neto = precio_unitario.to_d
    return neto if producto_impuestos.empty?

    total_impuestos = impuestos.sum do |impuesto|
      tasa = impuesto.valor_vigente || 0
      neto * tasa / 100.0
    end

    (neto + total_impuestos).round(2)
  end

  private

  def set_fecha_actualizacion
    self.fecha_actualizacion = Time.current
  end
end

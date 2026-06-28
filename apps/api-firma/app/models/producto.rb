# frozen_string_literal: true

class Producto < ApplicationRecord
  include Dte::DescuentosRecargos::Constants

  self.table_name = 'productos'
  self.record_timestamps = false

  before_update :set_fecha_actualizacion
  before_validation :normalizar_ambito_monto

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
  validate :ambito_monto_valido
  validate :ambito_monto_coherente_con_impuestos

  def afecto_iva?
    impuestos.exists?(abreviacion: 'IVA')
  end

  def afecto?
    clasificacion.afecto?
  end

  def ambito_monto_efectivo
    clasificacion.ambito_monto
  end

  def clasificacion
    Dte::DescuentosRecargos::ClasificacionMonto.desde_producto(self)
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

  def normalizar_ambito_monto
    raw = read_attribute(:ambito_monto)
    self.ambito_monto = nil if raw.blank? || raw.to_s.strip.upcase == 'AUTO'
  end

  def ambito_monto_valido
    return if read_attribute(:ambito_monto).blank?

    unless AMBITOS_MONTO.include?(read_attribute(:ambito_monto))
      errors.add(:ambito_monto, 'debe ser AFECTO, EXENTO_NO_AFECTO o NO_FACTURABLE')
    end
  end

  def ambito_monto_coherente_con_impuestos
    explicito = read_attribute(:ambito_monto)
    return if explicito.blank?

    if explicito == APLICA_SOBRE_NO_FACTURABLE && producto_impuestos.any?
      errors.add(:ambito_monto, 'no puede ser NO_FACTURABLE si el producto tiene impuestos')
    end

    if explicito == APLICA_SOBRE_EXENTO && producto_impuestos.any?
      errors.add(:ambito_monto, 'no puede ser EXENTO_NO_AFECTO si el producto tiene impuestos asignados')
    end

    if explicito == APLICA_SOBRE_AFECTO && producto_impuestos.empty?
      errors.add(:ambito_monto, 'requiere al menos un impuesto cuando es AFECTO')
    end
  end
end

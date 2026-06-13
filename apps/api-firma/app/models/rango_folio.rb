# frozen_string_literal: true

class RangoFolio < ApplicationRecord
  self.table_name = 'rango_folios'

  # Active Storage - archivo CAF
  has_one_attached :archivo_rango_folio

  # Relaciones
  belongs_to :empresa
  belongs_to :tipo_habilitado
  has_many :folios, dependent: :destroy

  # Validaciones
  validates :td, presence: true, length: { maximum: 10 }
  validates :d, presence: true, numericality: { only_integer: true }
  validates :h, presence: true, numericality: { only_integer: true }
  validates :fa, presence: true
  validates :rsask, presence: true, length: { maximum: 1000 }
  validates :rsapubk, presence: true, length: { maximum: 1000 }
  validates :archivo, presence: true, length: { maximum: 250 }, uniqueness: true
  validates :username, presence: true
  validates :fecha_subida, presence: true

  # Validación personalizada
  validate :rango_valido

  # Métodos
  def rango
    d..h
  end

  def cantidad_folios
    h - d + 1
  end

  def folios_disponibles
    folios.where(disponible: true, usado: false, anulado: false)
  end

  def folios_usados
    folios.where(usado: true)
  end

  private

  def rango_valido
    return if d.nil? || h.nil?

    errors.add(:h, 'debe ser mayor o igual que el valor desde') if h < d
  end
end

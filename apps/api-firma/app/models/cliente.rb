# frozen_string_literal: true

class Cliente < ApplicationRecord
  self.table_name = 'clientes'

  # Relaciones
  belongs_to :empresa
  has_many :documento_emitidos, dependent: :restrict_with_error

  # Validaciones
  validates :razon_social, presence: true, length: { maximum: 250 }
  validates :giro, presence: true, length: { maximum: 250 }
  validates :direccion, presence: true, length: { maximum: 250 }
  validates :fonos, presence: true, length: { maximum: 100 }
  validates :email, presence: true, length: { maximum: 100 }
  validates :rut, length: { maximum: 20 }, allow_blank: true
  validates :rut, uniqueness: { scope: :empresa_id, message: 'ya existe para esta empresa' }, if: -> { rut.present? }
  validates :codigo_postal, length: { maximum: 100 }, allow_blank: true
  validates :descuento, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end

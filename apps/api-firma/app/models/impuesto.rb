# frozen_string_literal: true

class Impuesto < ApplicationRecord
  self.table_name = 'impuestos'

  # Relaciones
  belongs_to :pais
  has_many :impuesto_valores, dependent: :destroy
  has_many :producto_impuestos, dependent: :destroy
  has_many :productos, through: :producto_impuestos

  # Scopes
  scope :por_pais, ->(pais_id) { where(pais_id: pais_id).order(:nombre) }
  scope :with_valor_vigente, -> { includes(:impuesto_valores) }

  # Validaciones
  validates :pais_id, presence: true
  validates :nombre, presence: true, length: { maximum: 200 }
  validates :abreviacion, presence: true, length: { maximum: 50 },
                          uniqueness: { scope: :pais_id, case_sensitive: false }

  def valor_vigente
    registro_valor_vigente&.valor
  end

  def registro_valor_vigente
    impuesto_valores.vigentes.ordenados.first
  end

  def tiene_productos?
    producto_impuestos.exists?
  end
end

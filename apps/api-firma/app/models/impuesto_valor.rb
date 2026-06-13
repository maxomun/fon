# frozen_string_literal: true

class ImpuestoValor < ApplicationRecord
  self.table_name = 'impuesto_valores'

  # Relaciones
  belongs_to :impuesto

  # Validaciones
  validates :valor, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :fecha_activacion, presence: true

  # Scopes
  scope :vigentes, -> {
    where('fecha_activacion <= ?', Time.current)
      .where('fecha_caducacion IS NULL OR fecha_caducacion > ?', Time.current)
  }

  # Métodos
  def vigente?
    fecha_activacion <= Time.current &&
      (fecha_caducacion.nil? || fecha_caducacion > Time.current)
  end
end

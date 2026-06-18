# frozen_string_literal: true

class ImpuestoValor < ApplicationRecord
  self.table_name = 'impuesto_valores'

  # Relaciones
  belongs_to :impuesto

  # Validaciones
  validates :valor, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :fecha_activacion, presence: true
  validate :fecha_caducacion_posterior_a_activacion

  # Scopes
  scope :vigentes, -> {
    where('fecha_activacion <= ?', Time.current)
      .where('fecha_caducacion IS NULL OR fecha_caducacion > ?', Time.current)
  }
  scope :ordenados, -> { order(fecha_activacion: :desc, id: :desc) }

  def vigente?
    fecha_activacion <= Time.current &&
      (fecha_caducacion.nil? || fecha_caducacion > Time.current)
  end

  private

  def fecha_caducacion_posterior_a_activacion
    return if fecha_caducacion.blank? || fecha_activacion.blank?
    return if fecha_caducacion > fecha_activacion

    errors.add(:fecha_caducacion, 'debe ser posterior a la fecha de activación')
  end
end

# frozen_string_literal: true

class Folio < ApplicationRecord
  self.table_name = 'folios'

  # Relaciones
  belongs_to :rango_folio
  belongs_to :empresa
  belongs_to :tipo_habilitado

  # Validaciones
  validates :numero, presence: true, numericality: { only_integer: true }
  validates :numero, uniqueness: { scope: :rango_folio_id, message: 'ya existe en este rango' }
  validates :numero, uniqueness: { scope: :tipo_habilitado_id, message: 'ya existe para este tipo de documento' }
  validates :usado, inclusion: { in: [true, false] }
  validates :anulado, inclusion: { in: [true, false] }
  validates :reservado, inclusion: { in: [true, false] }
  validates :disponible, inclusion: { in: [true, false] }

  # Scopes
  scope :disponibles, -> { where(disponible: true, usado: false, anulado: false, reservado: false) }
  scope :usados, -> { where(usado: true) }
  scope :anulados, -> { where(anulado: true) }
  scope :reservados, -> { where(reservado: true) }

  # Métodos
  def usar!
    update!(usado: true, disponible: false, reservado: false)
  end

  def reservar!
    update!(reservado: true, disponible: false)
  end

  def anular!
    update!(anulado: true, disponible: false)
  end

  def liberar!
    update!(reservado: false, disponible: true)
  end
end

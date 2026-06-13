# frozen_string_literal: true

class TipoHabilitado < ApplicationRecord
  self.table_name = 'tipo_habilitados'

  # Relaciones
  belongs_to :empresa
  belongs_to :tipo_documento
  has_many :rango_folios, dependent: :destroy
  has_many :folios, dependent: :destroy
  has_many :documento_emitidos, dependent: :restrict_with_error

  # Validaciones
  validates :fecha_habilitacion, presence: true
  validates :tipo_documento_id, uniqueness: { scope: :empresa_id, message: 'ya está habilitado para esta empresa' }

  # Delegaciones
  delegate :codigo, :nombre, :dte, to: :tipo_documento, prefix: true
end

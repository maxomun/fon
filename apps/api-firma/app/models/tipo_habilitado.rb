# frozen_string_literal: true

class TipoHabilitado < ApplicationRecord
  self.table_name = 'tipo_habilitados'

  # Relaciones
  belongs_to :empresa
  belongs_to :tipo_documento
  has_many :rango_folios, dependent: :restrict_with_error
  has_many :folios, dependent: :restrict_with_error
  has_many :documento_emitidos, dependent: :restrict_with_error

  # Validaciones
  validates :fecha_habilitacion, presence: true
  validates :tipo_documento_id, uniqueness: { scope: :empresa_id, message: 'ya está habilitado para esta empresa' }
  validate :tipo_documento_debe_ser_dte

  # Delegaciones
  delegate :codigo, :nombre, :dte, to: :tipo_documento, prefix: true

  def tiene_rangos_folio?
    rango_folios.exists?
  end

  def tiene_documentos_emitidos?
    documento_emitidos.exists?
  end

  def folios_disponibles_count
    folios.disponibles.count
  end

  private

  def tipo_documento_debe_ser_dte
    return if tipo_documento.blank?

    return if tipo_documento.dte?

    errors.add(:tipo_documento, 'debe ser un documento tributario electrónico (DTE)')
  end
end

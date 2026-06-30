# frozen_string_literal: true

class DocumentoEmitidoReferencia < ApplicationRecord
  self.table_name = 'documento_emitido_referencias'

  MAX_REFERENCIAS_POR_DOCUMENTO = 40
  CODIGOS_REFERENCIA_VALIDOS = (1..4).freeze

  belongs_to :documento_emitido
  belongs_to :tipo_referencia_documento
  belongs_to :documento_emitido_origen,
             class_name: 'DocumentoEmitido',
             optional: true

  validates :nro_linea, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_REFERENCIAS_POR_DOCUMENTO }
  validates :folio_referencia, presence: true, length: { maximum: 18 }
  validates :fecha_referencia, presence: true
  validates :razon_referencia, length: { maximum: 90 }, allow_blank: true
  validates :orden, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :nro_linea, uniqueness: { scope: :documento_emitido_id }
  validates :codigo_referencia,
            inclusion: { in: CODIGOS_REFERENCIA_VALIDOS },
            allow_nil: true

  validate :codigo_referencia_permitido_por_tipo

  scope :ordenados, -> { order(:orden, :nro_linea) }

  def self.crear_desde_hash!(documento_emitido:, referencia:)
    create!(
      documento_emitido: documento_emitido,
      nro_linea: referencia[:nro_linea] || referencia['nro_linea'],
      orden: referencia[:orden] || referencia['orden'],
      tipo_referencia_documento_id: referencia[:tipo_referencia_documento_id] || referencia['tipo_referencia_documento_id'],
      folio_referencia: referencia[:folio_referencia] || referencia['folio_referencia'],
      fecha_referencia: referencia[:fecha_referencia] || referencia['fecha_referencia'],
      codigo_referencia: referencia[:codigo_referencia] || referencia['codigo_referencia'],
      razon_referencia: referencia[:razon_referencia] || referencia['razon_referencia'],
      documento_emitido_origen_id: referencia[:documento_emitido_origen_id] || referencia['documento_emitido_origen_id']
    )
  end

  def tipo_documento_referencia_codigo
    tipo_referencia_documento.codigo_sii
  end

  private

  def codigo_referencia_permitido_por_tipo
    return if codigo_referencia.blank?
    return if tipo_referencia_documento&.permite_codigo_referencia?

    errors.add(:codigo_referencia, 'no está permitido para este tipo de documento referenciado')
  end
end

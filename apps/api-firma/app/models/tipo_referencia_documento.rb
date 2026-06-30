# frozen_string_literal: true

class TipoReferenciaDocumento < ApplicationRecord
  self.table_name = 'tipo_referencia_documentos'

  CATEGORIAS = %w[DTE DOCUMENTO_COMERCIAL DOCUMENTO_INTERNO OTRO].freeze

  has_many :documento_emitido_referencias, dependent: :restrict_with_error

  validates :codigo_sii, presence: true, length: { maximum: 10 }, uniqueness: true
  validates :nombre, presence: true, length: { maximum: 100 }
  validates :categoria, presence: true, inclusion: { in: CATEGORIAS }
  validates :activo, inclusion: { in: [true, false] }
  validates :requiere_folio, inclusion: { in: [true, false] }
  validates :requiere_fecha, inclusion: { in: [true, false] }
  validates :permite_codigo_referencia, inclusion: { in: [true, false] }
  validates :observacion, length: { maximum: 250 }, allow_blank: true

  scope :activos, -> { where(activo: true) }
  scope :ordenados, -> { order(:categoria, :codigo_sii) }

  def self.find_by_codigo_sii!(codigo)
    find_by!(codigo_sii: codigo.to_s)
  end
end

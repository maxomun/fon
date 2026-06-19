# frozen_string_literal: true

class TipoDocumento < ApplicationRecord
  self.table_name = 'tipo_documentos'

  # Relaciones
  has_many :tipo_habilitados, dependent: :destroy
  has_many :empresas, through: :tipo_habilitados
  has_many :documento_recibidos, dependent: :restrict_with_error

  # Validaciones
  validates :codigo, presence: true, length: { maximum: 10 }
  validates :nombre, presence: true, length: { maximum: 100 }
  validates :dte, inclusion: { in: [true, false] }
  validates :manual, inclusion: { in: [true, false] }

  # Scopes
  scope :dte, -> { where(dte: true) }
  scope :habilitables, -> { dte }
  scope :manuales, -> { where(manual: true) }

  # Constantes - Códigos SII
  FACTURA_ELECTRONICA = '33'
  FACTURA_EXENTA = '34'
  LIQUIDACION_FACTURA = '43'
  FACTURA_COMPRA = '46'
  NOTA_DEBITO = '56'
  NOTA_CREDITO = '61'
  BOLETA_ELECTRONICA = '39'
  BOLETA_EXENTA = '41'
end

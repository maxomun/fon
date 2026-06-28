# frozen_string_literal: true

class DocumentoEmitido < ApplicationRecord
  self.table_name = 'documento_emitidos'

  # Relaciones
  belongs_to :empresa
  belongs_to :tipo_habilitado
  belongs_to :cliente, optional: true
  belongs_to :usuario, class_name: 'User', foreign_key: :usuario_id
  belongs_to :asociado, class_name: 'DocumentoEmitido', optional: true
  belongs_to :dte_envio, optional: true
  has_many :documentos_asociados, class_name: 'DocumentoEmitido', foreign_key: :asociado_id, dependent: :nullify
  has_many :venta_detalles, dependent: :destroy
  has_many :documento_descuentos_recargos_globales,
           class_name: 'DocumentoDescuentoRecargoGlobal',
           dependent: :destroy

  # Validaciones
  validates :folio, presence: true, numericality: { only_integer: true }
  validates :dte, inclusion: { in: [true, false] }
  validates :manual, inclusion: { in: [true, false] }
  validates :rut_emisor, presence: true, length: { maximum: 20 }
  validates :razon_social_emisor, presence: true, length: { maximum: 250 }
  validates :giro_emisor, presence: true, length: { maximum: 250 }
  validates :direccion_emisor, presence: true, length: { maximum: 250 }
  validates :rut_receptor, presence: true, length: { maximum: 20 }
  validates :razon_social_receptor, presence: true, length: { maximum: 250 }
  validates :giro_receptor, presence: true, length: { maximum: 250 }
  validates :direccion_receptor, presence: true, length: { maximum: 250 }
  validates :ingreso_integrado, inclusion: { in: [true, false] }
  validates :ingreso_autonomo, inclusion: { in: [true, false] }
  validates :descripcion, length: { maximum: 100 }, allow_blank: true
  validates :ruta_imagen, length: { maximum: 250 }, uniqueness: true, allow_blank: true

  # Scopes
  scope :dte, -> { where(dte: true) }
  scope :manuales, -> { where(manual: true) }
  scope :integrados, -> { where(ingreso_integrado: true) }
  scope :autonomos, -> { where(ingreso_autonomo: true) }

  # Delegaciones
  delegate :tipo_documento, to: :tipo_habilitado

  # Métodos
  def tipo_documento_codigo
    tipo_habilitado.tipo_documento.codigo
  end

  def es_nota_credito?
    tipo_documento_codigo == TipoDocumento::NOTA_CREDITO
  end

  def es_nota_debito?
    tipo_documento_codigo == TipoDocumento::NOTA_DEBITO
  end

  def total
    venta_detalles.sum(&:subtotal_con_impuesto)
  end
end

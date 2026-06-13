# frozen_string_literal: true

class DocumentoRecibido < ApplicationRecord
  self.table_name = 'documento_recibidos'

  # Relaciones
  belongs_to :tipo_documento
  belongs_to :proveedor
  belongs_to :empresa
  belongs_to :user, optional: true

  # Validaciones
  validates :folio, presence: true, numericality: { only_integer: true }
  validates :folio, uniqueness: { scope: [:proveedor_id, :tipo_documento_id], message: 'ya existe para este proveedor y tipo de documento' }
  validates :razon_social_emisor, presence: true, length: { maximum: 250 }
  validates :giro_emisor, presence: true, length: { maximum: 250 }
  validates :direccion, presence: true, length: { maximum: 250 }
  validates :rut_emisor, length: { maximum: 20 }, allow_blank: true

  # Delegaciones
  delegate :codigo, :nombre, to: :tipo_documento, prefix: true
end

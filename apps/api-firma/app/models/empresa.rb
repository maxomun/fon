# frozen_string_literal: true

class Empresa < ApplicationRecord
  self.table_name = 'empresas'

  # Relaciones
  has_many :acteco_empresas, dependent: :destroy
  has_many :actecos, through: :acteco_empresas
  has_many :users, dependent: :restrict_with_error
  has_many :clientes, dependent: :destroy
  has_many :proveedores, dependent: :destroy
  has_many :productos, dependent: :destroy
  has_many :tipo_habilitados, dependent: :destroy
  has_many :tipo_documentos, through: :tipo_habilitados
  has_many :rango_folios, dependent: :destroy
  has_many :folios, dependent: :destroy
  has_many :documento_emitidos, dependent: :restrict_with_error
  has_many :documento_recibidos, dependent: :restrict_with_error
  has_many :certificados, through: :users

  # Obtiene el certificado vigente de la empresa para firmar DTEs
  def certificado_vigente
    certificados.vigentes.order(fecha_adjuncion: :desc).first
  end

  # Validaciones
  validates :rut, presence: true, length: { maximum: 20 }
  validates :razon_social, presence: true, length: { maximum: 250 }
  validates :giro, presence: true, length: { maximum: 250 }
  validates :direccion, presence: true, length: { maximum: 250 }
  validates :resolucion_timbre, presence: true, length: { maximum: 250 }
  validates :nombre_fantasia, presence: true, length: { maximum: 100 }
  validates :fecha_resolucion, presence: true
  validates :numero_resolucion, presence: true
  validates :archivo_logo, length: { maximum: 200 }, allow_blank: true
  validates :telefono1, length: { maximum: 20 }, allow_blank: true
  validates :telefono2, length: { maximum: 20 }, allow_blank: true
end

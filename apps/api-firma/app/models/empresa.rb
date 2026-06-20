# frozen_string_literal: true

class Empresa < ApplicationRecord
  self.table_name = 'empresas'
  self.record_timestamps = false

  before_update :set_fecha_actualizacion

  # Relaciones
  belongs_to :pais
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
  has_many :empresa_personas_autorizadas,
           class_name: 'EmpresaPersonaAutorizada',
           dependent: :destroy
  has_many :personas_autorizadas,
           through: :empresa_personas_autorizadas,
           source: :persona_autorizada

  # Certificado vigente para firmar DTEs (delega en Certificados::ResolverParaEmpresa).
  def certificado_vigente
    Certificados::ResolverParaEmpresa.call(empresa_id: id).certificado
  end

  def certificado_estado_payload
    resultado = Certificados::ResolverParaEmpresa.call(empresa_id: id)

    if resultado.success?
      certificado = resultado.certificado
      return {
        tiene_certificado_vigente: true,
        fecha_caducacion_certificado: formatear_fecha_certificado(certificado.fecha_caducacion)
      }
    end

    certificado_caducado = certificado_caducado_reciente
    {
      tiene_certificado_vigente: false,
      fecha_caducacion_certificado: formatear_fecha_certificado(certificado_caducado&.fecha_caducacion)
    }
  end

  # Validaciones
  validates :pais_id, presence: true
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

  private

  def certificado_caducado_reciente
    persona_ids = personas_autorizadas.activas.pluck(:id)
    return nil if persona_ids.empty?

    Certificado
      .where(persona_autorizada_id: persona_ids)
      .order(fecha_adjuncion: :desc)
      .detect(&:caducado?)
  end

  def formatear_fecha_certificado(fecha)
    return nil if fecha.blank?

    fecha.strftime('%Y-%m-%d')
  end

  def set_fecha_actualizacion
    self.fecha_actualizacion = Time.current
  end
end

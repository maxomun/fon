# frozen_string_literal: true

class PersonaAutorizada < ApplicationRecord
  self.table_name = 'personas_autorizadas'
  self.record_timestamps = false

  before_update :set_fecha_actualizacion
  before_validation :normalizar_componentes_nombre
  before_destroy :limpiar_onboarding_del_usuario
  after_destroy :eliminar_usuario_vinculado_si_corresponde

  belongs_to :user, optional: true
  has_many :certificados, dependent: :destroy
  has_many :empresa_personas_autorizadas,
           class_name: 'EmpresaPersonaAutorizada',
           dependent: :destroy
  has_many :empresas,
           through: :empresa_personas_autorizadas,
           source: :empresa

  ESTADO_INACTIVO = 0
  ESTADO_ACTIVO = 1

  validates :rut, presence: true, length: { maximum: 20 }, uniqueness: true
  validates :nombres, presence: true, length: { maximum: 250 }
  validates :apellido_paterno, length: { maximum: 250 }, allow_blank: true
  validates :apellido_materno, length: { maximum: 250 }, allow_blank: true
  validates :email, presence: true, length: { maximum: 200 }, uniqueness: true
  validates :estado, presence: true, inclusion: { in: [ESTADO_INACTIVO, ESTADO_ACTIVO] }
  validates :orden, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :activas, -> { where(estado: ESTADO_ACTIVO) }
  scope :inactivas, -> { where(estado: ESTADO_INACTIVO) }
  scope :por_prioridad, -> { order(:orden, :id) }

  def activa?
    estado == ESTADO_ACTIVO
  end

  def inactiva?
    estado == ESTADO_INACTIVO
  end

  def nombre_completo
    [nombres, apellido_paterno, apellido_materno].compact_blank.join(' ')
  end

  def certificado_vigente
    Certificados::ResolverParaEmpresa.certificado_vigente_de(self)
  end

  def asignacion_en(empresa_id)
    empresa_personas_autorizadas.find_by(empresa_id: empresa_id)
  end

  def vinculada_a_empresa?(empresa_id)
    return false unless activa?

    empresas.exists?(id: empresa_id)
  end

  def administrador_en_empresa?(empresa_id)
    return false unless activa?

    empresa_personas_autorizadas.administradores.exists?(empresa_id: empresa_id)
  end

  def empresas_como_administrador
    Empresa
      .joins(:empresa_personas_autorizadas)
      .where(
        empresa_personas_autorizadas: {
          persona_autorizada_id: id,
          es_administrador_empresa: true
        }
      )
      .order(:razon_social)
  end

  def sincronizar_nombre_a_usuario!
    return unless user

    user.update!(
      nombres: nombres,
      apellido_paterno: apellido_paterno,
      apellido_materno: apellido_materno,
      email: email
    )
  end

  def puede_eliminarse?
    empresa_personas_autorizadas.none? && certificados.none?
  end

  private

  def normalizar_componentes_nombre
    return if nombres.blank? && apellido_paterno.blank? && apellido_materno.blank?

    normalizados = PersonasAutorizadas::NormalizarNombres.call(
      nombres: nombres,
      apellido_paterno: apellido_paterno,
      apellido_materno: apellido_materno
    )

    self.nombres = normalizados[:nombres] if nombres.present?
    self.apellido_paterno = normalizados[:apellido_paterno] if apellido_paterno.present?
    self.apellido_materno = normalizados[:apellido_materno] if apellido_materno.present?
  end

  def limpiar_onboarding_del_usuario
    @login_user_id = user_id
    user&.onboarding_tokens&.destroy_all
  end

  def eliminar_usuario_vinculado_si_corresponde
    return if @login_user_id.blank?

    login_user = User.find_by(id: @login_user_id)
    return unless login_user
    return unless login_user.eliminable_junto_a_persona_autorizada?

    login_user.destroy!
  end

  def set_fecha_actualizacion
    self.fecha_actualizacion = Time.current
  end
end

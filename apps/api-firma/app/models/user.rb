# frozen_string_literal: true

class User < ApplicationRecord
  self.table_name = 'users'

  ROL_ADMINISTRADOR_FON = 'administrador_fon'

  # Autenticación segura con bcrypt
  has_secure_password validations: false

  # Validación de password con confirmación (solo cuando se cambia el password)
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: { message: 'debe ser proporcionada' }, if: -> { password.present? }
  validate :validar_politica_password, if: -> { password.present? }

  # Relaciones
  has_many :user_roles, class_name: 'UserRol', dependent: :destroy
  has_many :roles, through: :user_roles, source: :rol, class_name: 'Rol'
  has_one :persona_autorizada, dependent: :nullify
  has_many :refresh_tokens, dependent: :destroy
  has_many :token_blacklists, dependent: :destroy
  has_many :onboarding_tokens, dependent: :destroy
  has_many :documento_emitidos, foreign_key: :usuario_id, dependent: :restrict_with_error
  has_many :dte_envios, foreign_key: :usuario_id, dependent: :restrict_with_error
  has_many :documento_recibidos, dependent: :restrict_with_error

  # Validaciones
  validates :username, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :email, presence: true, length: { maximum: 200 }, uniqueness: true
  validates :password_digest, presence: true, length: { maximum: 200 }
  validates :lenguaje, presence: true, length: { maximum: 10 }
  validates :estado, presence: true
  validates :visible, inclusion: { in: [true, false] }
  validates :nombres, length: { maximum: 250 }, allow_blank: true
  validates :apellido_paterno, length: { maximum: 250 }, allow_blank: true
  validates :apellido_materno, length: { maximum: 250 }, allow_blank: true

  # Scopes
  scope :activos, -> { where(estado: 1) }
  scope :inactivos, -> { where(estado: 0) }
  scope :visibles, -> { where(visible: true) }

  # Estados
  ESTADO_INACTIVO = 0
  ESTADO_ACTIVO = 1

  def activo?
    estado == ESTADO_ACTIVO
  end

  def inactivo?
    estado == ESTADO_INACTIVO
  end

  def admin?
    roles.exists?(esadmin: true)
  end

  def tiene_rol?(codigo_rol)
    roles.exists?(codigo: codigo_rol)
  end

  def administrador_fon?
    tiene_rol?(ROL_ADMINISTRADOR_FON)
  end

  def email_verificado?
    email_verificado_at.present?
  end

  def onboarding_completado?
    onboarding_completado_at.present?
  end

  def perfil_persona_autorizada?
    persona_autorizada.present? && !administrador_fon?
  end

  def requiere_verificacion_email?
    perfil_persona_autorizada? && !email_verificado?
  end

  def requiere_onboarding?
    perfil_persona_autorizada? && !onboarding_completado?
  end

  def nombre_completo
    [nombres, apellido_paterno, apellido_materno].compact_blank.join(' ')
  end

  def perfil_persona?
    nombres.present?
  end

  def vinculado_a_empresa?(empresa_id)
    return true if administrador_fon?

    persona_autorizada&.vinculada_a_empresa?(empresa_id) || false
  end

  def administrador_en_empresa?(empresa_id)
    return true if administrador_fon?

    persona_autorizada&.administrador_en_empresa?(empresa_id) || false
  end

  def empresas_asignadas
    return Empresa.order(:razon_social) if administrador_fon?

    persona_autorizada&.empresas&.order(:razon_social) || Empresa.none
  end

  def empresas_como_administrador
    return Empresa.order(:razon_social) if administrador_fon?

    persona_autorizada&.empresas_como_administrador || Empresa.none
  end

  def activar!
    update!(estado: ESTADO_ACTIVO)
  end

  def desactivar!
    update!(estado: ESTADO_INACTIVO)
  end

  # Revoca todas las sesiones activas del usuario
  def revocar_todas_las_sesiones!
    refresh_tokens.active.each(&:revoke!)
  end

  def eliminable_junto_a_persona_autorizada?
    return false if administrador_fon?

    documento_emitidos.none? && documento_recibidos.none?
  end

  def puede_restablecer_password?
    return false unless activo?

    !requiere_verificacion_email? && !requiere_onboarding?
  end

  private

  def validar_politica_password
    resultado = Users::ValidarPassword.call(password: password)
    resultado[:errors].each { |mensaje| errors.add(:password, mensaje) }
  end
end

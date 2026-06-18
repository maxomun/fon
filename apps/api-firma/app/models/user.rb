# frozen_string_literal: true

class User < ApplicationRecord
  self.table_name = 'users'

  # Autenticación segura con bcrypt
  has_secure_password validations: false

  # Validación de password con confirmación (solo cuando se cambia el password)
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: { message: 'debe ser proporcionada' }, if: -> { password.present? }
  validates :password, length: { minimum: 6, message: 'debe tener al menos 6 caracteres' }, if: -> { password.present? }

  # Relaciones
  belongs_to :empresa, optional: true
  has_one :persona, dependent: :destroy
  has_many :user_roles, class_name: 'UserRol', dependent: :destroy
  has_many :roles, through: :user_roles, source: :rol, class_name: 'Rol'
  has_one :persona_autorizada, dependent: :nullify
  has_many :refresh_tokens, dependent: :destroy
  has_many :token_blacklists, dependent: :destroy
  has_many :documento_emitidos, foreign_key: :usuario_id, dependent: :restrict_with_error
  has_many :documento_recibidos, dependent: :restrict_with_error

  # Validaciones
  validates :username, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :email, presence: true, length: { maximum: 200 }, uniqueness: true
  validates :password_digest, presence: true, length: { maximum: 200 }
  validates :lenguaje, presence: true, length: { maximum: 10 }
  validates :estado, presence: true
  validates :visible, inclusion: { in: [true, false] }

  # Scopes
  scope :activos, -> { where(estado: 1) }
  scope :inactivos, -> { where(estado: 0) }
  scope :visibles, -> { where(visible: true) }

  # Estados
  ESTADO_INACTIVO = 0
  ESTADO_ACTIVO = 1

  # Métodos
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
end

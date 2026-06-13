# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  self.table_name = 'refresh_tokens'

  # Relaciones
  belongs_to :user

  # Validaciones
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where('expires_at > ? AND revoked_at IS NULL', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  # Callbacks
  before_validation :generate_token, on: :create

  # Métodos
  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !expired? && !revoked?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  # Revoca todos los refresh tokens del usuario
  def self.revoke_all_for_user!(user_id)
    where(user_id: user_id, revoked_at: nil).update_all(revoked_at: Time.current)
  end

  # Limpia tokens expirados
  def self.cleanup_expired!
    expired.delete_all
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
    self.expires_at ||= JsonWebToken::REFRESH_TOKEN_EXPIRY.from_now
  end
end

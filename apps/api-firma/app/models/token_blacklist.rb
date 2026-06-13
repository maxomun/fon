# frozen_string_literal: true

class TokenBlacklist < ApplicationRecord
  self.table_name = 'token_blacklists'

  # Relaciones
  belongs_to :user, optional: true

  # Validaciones
  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  # Scopes
  scope :expired, -> { where('exp < ?', Time.current) }
  scope :active, -> { where('exp >= ?', Time.current) }

  # Limpia tokens expirados de la blacklist (ejecutar periódicamente)
  def self.cleanup_expired!
    expired.delete_all
  end
end

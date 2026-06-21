# frozen_string_literal: true

class OnboardingToken < ApplicationRecord
  self.record_timestamps = false

  PROPOSITO_VERIFICAR_EMAIL = 'verificar_email'
  PROPOSITO_ESTABLECER_PASSWORD = 'establecer_password'
  PROPOSITO_RESTABLECER_PASSWORD = 'restablecer_password'
  PROPOSITOS = [
    PROPOSITO_VERIFICAR_EMAIL,
    PROPOSITO_ESTABLECER_PASSWORD,
    PROPOSITO_RESTABLECER_PASSWORD
  ].freeze

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true, length: { maximum: 64 }
  validates :proposito, presence: true, inclusion: { in: PROPOSITOS }
  validates :expires_at, presence: true

  scope :activos, -> { where(used_at: nil).where('expires_at > ?', Time.current) }
  scope :verificar_email, -> { where(proposito: PROPOSITO_VERIFICAR_EMAIL) }
  scope :establecer_password, -> { where(proposito: PROPOSITO_ESTABLECER_PASSWORD) }
  scope :restablecer_password, -> { where(proposito: PROPOSITO_RESTABLECER_PASSWORD) }

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

    def self.find_by_raw_token(raw_token)
      find_by(token_digest: digest(raw_token))
    end

    def self.find_active_by_raw_token(raw_token)
    activos.find_by(token_digest: digest(raw_token))
  end

  def activo?
    used_at.nil? && expires_at > Time.current
  end

  def expirado?
    expires_at <= Time.current
  end

  def consumido?
    used_at.present?
  end

  def consumir!
    update!(used_at: Time.current)
  end
end

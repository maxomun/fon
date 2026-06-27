# frozen_string_literal: true

class DteEnvio < ApplicationRecord
  self.table_name = 'dte_envios'

  belongs_to :empresa
  belongs_to :usuario, class_name: 'User'
  has_one_attached :xml_firmado
  has_many :documento_emitidos, dependent: :restrict_with_error

  validates :empresa_id, presence: true
  validates :usuario_id, presence: true
end

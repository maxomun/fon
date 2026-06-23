# frozen_string_literal: true

class AuditEvent < ApplicationRecord
  self.table_name = 'audit_events'

  RESULTADO_EXITO = 'success'
  RESULTADO_FALLO = 'failure'
  RESULTADOS = [RESULTADO_EXITO, RESULTADO_FALLO].freeze

  belongs_to :actor_user, class_name: 'User', optional: true
  belongs_to :empresa, optional: true

  validates :accion, presence: true, length: { maximum: 100 }
  validates :categoria, presence: true, length: { maximum: 50 }
  validates :resultado, presence: true, inclusion: { in: RESULTADOS }

  scope :recientes, -> { order(created_at: :desc) }
  scope :auth, -> { where(categoria: Auditoria::Acciones::CATEGORIA_AUTH) }
  scope :usuarios, -> { where(categoria: Auditoria::Acciones::CATEGORIA_USUARIOS) }
  scope :personas, -> { where(categoria: Auditoria::Acciones::CATEGORIA_PERSONAS) }
  scope :empresa_config, -> { where(categoria: Auditoria::Acciones::CATEGORIA_EMPRESA) }
  scope :certificados, -> { where(categoria: Auditoria::Acciones::CATEGORIA_CERTIFICADOS) }
  scope :folios, -> { where(categoria: Auditoria::Acciones::CATEGORIA_FOLIOS) }
  scope :catalogo, -> { where(categoria: Auditoria::Acciones::CATEGORIA_CATALOGO) }
  scope :dte, -> { where(categoria: Auditoria::Acciones::CATEGORIA_DTE) }
  scope :productos, -> { where(categoria: Auditoria::Acciones::CATEGORIA_PRODUCTOS) }
  scope :de_empresa, ->(empresa_id) { where(empresa_id: empresa_id) }
end

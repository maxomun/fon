# frozen_string_literal: true

class ActecoEmpresa < ApplicationRecord
  self.table_name = 'acteco_empresas'

  # Relaciones
  belongs_to :empresa
  belongs_to :acteco

  # Validaciones
  validates :acteco_id, uniqueness: { scope: :empresa_id, message: 'ya está asignado a esta empresa' }
end

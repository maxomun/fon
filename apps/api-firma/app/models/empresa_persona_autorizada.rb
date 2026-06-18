# frozen_string_literal: true

class EmpresaPersonaAutorizada < ApplicationRecord
  self.table_name = 'empresa_personas_autorizadas'
  self.record_timestamps = false

  belongs_to :empresa
  belongs_to :persona_autorizada

  validates :persona_autorizada_id, uniqueness: { scope: :empresa_id, message: 'ya está asignada a esta empresa' }
end

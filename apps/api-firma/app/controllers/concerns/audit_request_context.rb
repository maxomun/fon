# frozen_string_literal: true

module AuditRequestContext
  extend ActiveSupport::Concern

  included do
    before_action :set_auditoria_request_context
  end

  private

  def set_auditoria_request_context
    Auditoria::Contexto.request = request
  end
end

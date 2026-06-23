# frozen_string_literal: true

module Auditoria
  class Contexto < ActiveSupport::CurrentAttributes
    attribute :request
    attribute :actor

    def ip
      request&.remote_ip
    end

    def user_agent
      request&.user_agent&.truncate(500)
    end

    def request_id
      request&.request_id
    end
  end
end

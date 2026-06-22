# frozen_string_literal: true

module UserSerializable
  extend ActiveSupport::Concern

  private

  def user_admin_payload(user, detalle: false)
    Users::AdminPayload.call(user, detalle: detalle)
  end
end

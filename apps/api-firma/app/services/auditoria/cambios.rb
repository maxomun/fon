# frozen_string_literal: true

module Auditoria
  module Cambios
    IGNORAR = %w[updated_at timestamp password_digest].freeze

    module_function

    def desde_modelo(modelo, solo: nil)
      return {} unless modelo.respond_to?(:saved_changes)

      cambios = modelo.saved_changes.except(*IGNORAR)
      cambios = cambios.slice(*Array(solo).map(&:to_s)) if solo.present?

      cambios
    end

    def campo(modelo, atributo)
      return {} unless modelo.respond_to?(:attribute_before_last_save)

      antes = modelo.attribute_before_last_save(atributo)
      despues = modelo.public_send(atributo)
      return {} if antes == despues

      { atributo.to_s => [antes, despues] }
    end
  end
end

# frozen_string_literal: true

module Impuestos
  # Registra un nuevo valor de impuesto y cierra los registros abiertos anteriores.
  #
  # Reglas:
  # - Valores con fecha_caducacion NULL y fecha_activacion anterior reciben
  #   fecha_caducacion = fecha_activacion del nuevo valor.
  # - El nuevo registro se valida antes de persistir (valor 0-100, fechas coherentes).
  #
  # Ejemplo:
  #   resultado = Impuestos::RegistrarValor.call(
  #     impuesto: impuesto,
  #     attributes: { valor: 19, fecha_activacion: Time.current }
  #   )
  #
  class RegistrarValor
    Result = Struct.new(:impuesto_valor, :errors, keyword_init: true) do
      def success?
        errors.blank? && impuesto_valor&.persisted?
      end
    end

    def self.call(impuesto:, attributes:)
      new(impuesto: impuesto, attributes: attributes).call
    end

    def initialize(impuesto:, attributes:)
      @impuesto = impuesto
      @attributes = attributes
    end

    def call
      impuesto_valor = @impuesto.impuesto_valores.build(@attributes)

      unless impuesto_valor.valid?
        return failure(impuesto_valor, impuesto_valor.errors.full_messages)
      end

      ImpuestoValor.transaction do
        cerrar_valores_anteriores(impuesto_valor.fecha_activacion)
        impuesto_valor.save!
      end

      Result.new(impuesto_valor: impuesto_valor, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record, e.record.errors.full_messages)
    end

    private

    def cerrar_valores_anteriores(fecha_activacion)
      @impuesto.impuesto_valores
        .where(fecha_caducacion: nil)
        .where('fecha_activacion < ?', fecha_activacion)
        .find_each do |valor|
          valor.update!(fecha_caducacion: fecha_activacion)
        end
    end

    def failure(impuesto_valor, errors)
      Result.new(impuesto_valor: impuesto_valor, errors: Array(errors))
    end
  end
end

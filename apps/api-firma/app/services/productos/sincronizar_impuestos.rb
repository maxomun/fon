# frozen_string_literal: true

module Productos
  class SincronizarImpuestos
    Resultado = Struct.new(:success?, :error, keyword_init: true)

    def self.call(producto:, impuesto_ids:, pais_id:)
      new(producto: producto, impuesto_ids: impuesto_ids, pais_id: pais_id).call
    end

    def initialize(producto:, impuesto_ids:, pais_id:)
      @producto = producto
      @impuesto_ids = Array(impuesto_ids).map(&:to_i).uniq.reject(&:zero?)
      @pais_id = pais_id
    end

    def call
      valid_ids = Impuesto.where(id: @impuesto_ids, pais_id: @pais_id).pluck(:id)

      if @impuesto_ids.any? && valid_ids.size != @impuesto_ids.size
        return Resultado.new(
          success?: false,
          error: 'Uno o más impuestos no pertenecen al país de la empresa'
        )
      end

      ActiveRecord::Base.transaction do
        @producto.producto_impuestos.where.not(impuesto_id: valid_ids).destroy_all

        valid_ids.each do |impuesto_id|
          @producto.producto_impuestos.find_or_create_by!(impuesto_id: impuesto_id)
        end
      end

      Resultado.new(success?: true, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Resultado.new(success?: false, error: e.record.errors.full_messages.join(', '))
    end
  end
end

# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Suma subtotales por ámbito a partir de ítems ya preparados (post línea).
    class BasesDocumento
      include Constants

      def self.desde_items(items)
        new(items).to_h
      end

      def initialize(items)
        @items = items
      end

      def to_h
        bases = {
          APLICA_SOBRE_AFECTO => 0,
          APLICA_SOBRE_EXENTO => 0,
          APLICA_SOBRE_NO_FACTURABLE => 0
        }

        items.each do |item|
          ambito = item[:ambito_monto] || item['ambito_monto']
          unless ambito
            afecto = item.key?(:afecto) ? item[:afecto] : item['afecto']
            ambito = afecto ? APLICA_SOBRE_AFECTO : APLICA_SOBRE_EXENTO
          end

          neto = (item[:neto] || item['neto']).to_i
          bases[ambito] += neto if bases.key?(ambito)
        end

        bases
      end

      private

      attr_reader :items
    end
  end
end

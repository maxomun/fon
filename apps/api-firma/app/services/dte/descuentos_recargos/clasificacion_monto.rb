# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Resuelve el ámbito de monto (afecto / exento / no facturable) para productos e ítems.
    class ClasificacionMonto
      include Constants

      def self.desde_producto(producto)
        new(
          ambito_monto: producto.read_attribute(:ambito_monto),
          tiene_impuestos: producto.producto_impuestos.any?
        )
      end

      def self.desde_item(item)
        explicito = item[:ambito_monto] || item['ambito_monto']
        if explicito && !explicito.to_s.strip.empty? && explicito.to_s.strip.upcase != 'AUTO'
          return new(ambito_monto: explicito, tiene_impuestos: false)
        end

        new(
          ambito_monto: nil,
          tiene_impuestos: item[:afecto] || item['afecto'],
          no_facturable: item[:no_facturable] || item['no_facturable']
        )
      end

      def initialize(ambito_monto:, tiene_impuestos:, no_facturable: false)
        @ambito_monto_explicito = normalizar_explicito(ambito_monto)
        @tiene_impuestos = tiene_impuestos
        @no_facturable = no_facturable
      end

      def ambito_monto
        return @ambito_monto_explicito if @ambito_monto_explicito

        return APLICA_SOBRE_NO_FACTURABLE if @no_facturable

        @tiene_impuestos ? APLICA_SOBRE_AFECTO : APLICA_SOBRE_EXENTO
      end

      def afecto?
        ambito_monto == APLICA_SOBRE_AFECTO
      end

      def exento?
        ambito_monto == APLICA_SOBRE_EXENTO
      end

      def no_facturable?
        ambito_monto == APLICA_SOBRE_NO_FACTURABLE
      end

      def ind_exe_detalle
        case ambito_monto
        when APLICA_SOBRE_EXENTO then IND_EXE_EXENTO
        when APLICA_SOBRE_NO_FACTURABLE then IND_EXE_NO_FACTURABLE
        end
      end

      private

      def normalizar_explicito(valor)
        return nil if valor.nil?

        raw = valor.to_s.strip.upcase
        return nil if raw.empty? || raw == 'AUTO'

        raw
      end
    end
  end
end

# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Resultado del cálculo de una línea de detalle (paso 1 del algoritmo).
    class LineaCalculada
      include Constants

      attr_reader :datos_origen, :monto_bruto, :descuento_linea, :recargo_linea, :monto_neto, :ambito_monto

      def self.from_item(item)
        new(item)
      end

      def initialize(item)
        @datos_origen = item
        @ambito_monto = resolver_ambito(item)
        @monto_bruto = calcular_bruto(item)
        @descuento_linea = calcular_descuento_linea(item, @monto_bruto)
        @recargo_linea = calcular_recargo_linea(item, @monto_bruto)
        @monto_neto = (@monto_bruto - @descuento_linea + @recargo_linea).to_i
      end

      def afecto?
        ambito_monto == APLICA_SOBRE_AFECTO
      end

      def impuestos
        Array(datos_origen[:impuestos] || datos_origen['impuestos'])
      end

      def to_h
        {
          monto_bruto: monto_bruto,
          descuento_linea: descuento_linea,
          recargo_linea: recargo_linea,
          monto_neto: monto_neto,
          ambito_monto: ambito_monto,
          datos_origen: datos_origen
        }
      end

      private

      def resolver_ambito(item)
        Dte::DescuentosRecargos::ClasificacionMonto.desde_item(item).ambito_monto
      end

      def calcular_bruto(item)
        cantidad = (item[:cantidad] || item['cantidad']).to_f
        precio = (item[:precio_unitario] || item['precio_unitario']).to_f
        (cantidad * precio).to_i
      end

      def calcular_descuento_linea(item, bruto)
        monto = (item[:descuento] || item['descuento']).to_f
        pct = (item[:descuento_pct] || item['descuento_pct']).to_f

        return monto.to_i if monto.positive?
        return (bruto * pct / 100.0).to_i if pct.positive?

        0
      end

      def calcular_recargo_linea(item, bruto)
        monto = (item[:recargo] || item['recargo']).to_f
        pct = (item[:recargo_pct] || item['recargo_pct']).to_f

        return monto.to_i if monto.positive?
        return (bruto * pct / 100.0).to_i if pct.positive?

        0
      end
    end
  end
end

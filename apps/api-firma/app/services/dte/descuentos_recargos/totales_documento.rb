# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Totales finales del documento tras líneas y movimientos globales.
    class TotalesDocumento
      attr_reader :subtotal_afecto, :subtotal_exento, :subtotal_no_facturable,
                  :neto_afecto, :neto_exento, :neto_no_facturable,
                  :tasa_iva, :iva, :otros_impuestos, :total

      def initialize(
        subtotal_afecto:,
        subtotal_exento:,
        subtotal_no_facturable:,
        neto_afecto:,
        neto_exento:,
        neto_no_facturable:,
        tasa_iva:,
        iva:,
        otros_impuestos:,
        total:
      )
        @subtotal_afecto = subtotal_afecto
        @subtotal_exento = subtotal_exento
        @subtotal_no_facturable = subtotal_no_facturable
        @neto_afecto = neto_afecto
        @neto_exento = neto_exento
        @neto_no_facturable = neto_no_facturable
        @tasa_iva = tasa_iva
        @iva = iva
        @otros_impuestos = otros_impuestos
        @total = total
      end

      # Compatible con GeneradorXml#construir_totales
      def to_generador_xml
        {
          neto_afecto: neto_afecto,
          neto_exento: neto_exento,
          neto_no_facturable: neto_no_facturable,
          tasa_iva: tasa_iva,
          iva: iva,
          otros_impuestos: otros_impuestos,
          total_impuestos: iva + otros_impuestos.sum { |imp| imp[:monto] },
          total: total
        }
      end

      def to_h
        to_generador_xml.merge(
          subtotal_afecto: subtotal_afecto,
          subtotal_exento: subtotal_exento,
          subtotal_no_facturable: subtotal_no_facturable,
          neto_no_facturable: neto_no_facturable
        )
      end
    end
  end
end

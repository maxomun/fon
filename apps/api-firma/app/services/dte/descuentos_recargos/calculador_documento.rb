# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Motor de cálculo (§6 prompt-descuentos-y-recargos.md).
    # Aislado del pipeline DTE: no persiste ni genera XML.
    class CalculadorDocumento
      include Constants

      def self.call(items:, movimientos_globales: [])
        new(items: items, movimientos_globales: movimientos_globales).call
      end

      def initialize(items:, movimientos_globales: [])
        @items = items
        @movimientos_globales = normalizar_movimientos(movimientos_globales)
      end

      def call
        lineas = items.map { |item| LineaCalculada.from_item(item) }

        subtotales = sumar_bases(lineas)

        validacion = ValidadorMovimientos.call(
          movimientos: movimientos_globales,
          bases: subtotales
        )
        unless validacion[:success]
          raise Error, validacion[:errors].join('; ')
        end

        movimientos_con_monto, netos_finales = aplicar_movimientos_globales(subtotales)

        impuestos = calcular_impuestos(lineas, netos_finales[:neto_afecto])
        total = netos_finales[:neto_afecto] +
                netos_finales[:neto_exento] +
                netos_finales[:neto_no_facturable] +
                impuestos[:total_impuestos]

        {
          success: true,
          lineas: lineas,
          subtotales: subtotales,
          movimientos_globales: movimientos_con_monto.map(&:to_h),
          totales: TotalesDocumento.new(
            subtotal_afecto: subtotales[APLICA_SOBRE_AFECTO],
            subtotal_exento: subtotales[APLICA_SOBRE_EXENTO],
            subtotal_no_facturable: subtotales[APLICA_SOBRE_NO_FACTURABLE],
            neto_afecto: netos_finales[:neto_afecto],
            neto_exento: netos_finales[:neto_exento],
            neto_no_facturable: netos_finales[:neto_no_facturable],
            tasa_iva: impuestos[:tasa_iva],
            iva: impuestos[:iva],
            otros_impuestos: impuestos[:otros_impuestos],
            total: total
          )
        }
      rescue Error => e
        { success: false, error: e.message }
      end

      private

      attr_reader :items, :movimientos_globales

      def normalizar_movimientos(raw)
        Array(raw).map.with_index(1) do |entry, index|
          if entry.is_a?(MovimientoGlobal)
            entry.nro_linea ||= index
            entry.orden ||= index
            entry
          else
            MovimientoGlobal.from_hash(entry, nro_linea: index, orden: index)
          end
        end
      end

      def sumar_bases(lineas)
        bases = {
          APLICA_SOBRE_AFECTO => 0,
          APLICA_SOBRE_EXENTO => 0,
          APLICA_SOBRE_NO_FACTURABLE => 0
        }

        lineas.each do |linea|
          bases[linea.ambito_monto] += linea.monto_neto
        end

        bases
      end

      def aplicar_movimientos_globales(subtotales)
        netos = {
          neto_afecto: subtotales[APLICA_SOBRE_AFECTO],
          neto_exento: subtotales[APLICA_SOBRE_EXENTO],
          neto_no_facturable: subtotales[APLICA_SOBRE_NO_FACTURABLE]
        }

        movimientos_por_ambito = movimientos_globales.group_by(&:aplica_sobre)

        movimientos_por_ambito.each do |ambito, movimientos|
          campo = campo_neto_para(ambito)
          base_actual = netos[campo]

          movimientos.sort_by(&:orden).each do |mov|
            monto = calcular_monto_movimiento(base_actual, mov)
            mov.monto_calculado = monto

            if mov.descuento? && monto > base_actual
              raise Error,
                    "Descuento de #{monto} supera la base #{ambito} (#{base_actual})"
            end

            base_actual = if mov.descuento?
                            base_actual - monto
                          else
                            base_actual + monto
                          end
          end

          netos[campo] = base_actual
        end

        [movimientos_globales, netos]
      end

      def campo_neto_para(ambito)
        case ambito
        when APLICA_SOBRE_AFECTO then :neto_afecto
        when APLICA_SOBRE_EXENTO then :neto_exento
        when APLICA_SOBRE_NO_FACTURABLE then :neto_no_facturable
        else
          raise Error, "Ámbito desconocido: #{ambito}"
        end
      end

      def calcular_monto_movimiento(base, mov)
        if mov.porcentaje?
          (base * mov.valor / 100.0).to_i
        else
          mov.valor.to_i
        end
      end

      def calcular_impuestos(lineas, neto_afecto_final)
        return { tasa_iva: 0, iva: 0, otros_impuestos: [], total_impuestos: 0 } if neto_afecto_final <= 0

        # Tasa IVA desde líneas afectas (misma convención que dte_controller#calcular_totales)
        tasa_iva = 0
        lineas.select(&:afecto?).each do |linea|
          iva = linea.impuestos.find { |imp| (imp[:codigo] || imp['codigo']) == 'IVA' }
          next unless iva

          tasa_iva = (iva[:tasa] || iva['tasa']).to_f
          break if tasa_iva.positive?
        end

        iva = (neto_afecto_final * tasa_iva / 100.0).to_i
        otros = []

        {
          tasa_iva: tasa_iva,
          iva: iva,
          otros_impuestos: otros,
          total_impuestos: iva + otros.sum { |imp| imp[:monto] }
        }
      end
    end
  end
end

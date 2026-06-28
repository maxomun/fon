# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Validaciones del §7 de prompt-descuentos-y-recargos.md
    class ValidadorMovimientos
      include Constants

      def self.call(movimientos:, bases: nil)
        new(movimientos: movimientos, bases: bases).call
      end

      def initialize(movimientos:, bases: nil)
        @movimientos = movimientos
        @bases = bases || {}
      end

      def call
        errores = []
        errores << "Máximo #{MAX_MOVIMIENTOS_GLOBALES} movimientos globales" if movimientos.size > MAX_MOVIMIENTOS_GLOBALES

        movimientos.each_with_index do |mov, index|
          errores.concat(validar_movimiento(mov, index))
        end

        errores.concat(validar_numeracion)

        if errores.empty?
          { success: true }
        else
          { success: false, errors: errores }
        end
      end

      private

      attr_reader :movimientos, :bases

      def validar_movimiento(mov, index)
        prefijo = "descuentos_recargos_globales[#{index}]"
        errores = []

        unless TPOS_MOVIMIENTO.include?(mov.tipo_movimiento)
          errores << "#{prefijo}: tipo_movimiento debe ser D o R"
        end

        unless TIPOS_VALOR.include?(mov.tipo_valor)
          errores << "#{prefijo}: tipo_valor inválido"
        end

        unless AMBITOS_MONTO.include?(mov.aplica_sobre)
          errores << "#{prefijo}: aplica_sobre inválido"
        end

        errores << "#{prefijo}: valor debe ser mayor que 0" unless mov.valor.positive?

        if mov.porcentaje? && mov.valor > 100
          errores << "#{prefijo}: porcentaje no puede superar 100"
        end

        if mov.monto_fijo? && mov.descuento? && !bases.empty?
          base = bases[mov.aplica_sobre]
          if base && mov.valor.to_i > base
            errores << "#{prefijo}: descuento ($#{mov.valor.to_i}) supera la base #{mov.aplica_sobre} ($#{base})"
          end
        end

        errores
      end

      def validar_numeracion
        numeros = movimientos.map(&:nro_linea).compact
        return [] if numeros.empty?

        esperados = (1..numeros.size).to_a
        return [] if numeros == esperados

        ['NroLinDR debe ser correlativo desde 1']
      end
    end
  end
end

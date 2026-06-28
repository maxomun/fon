# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Parsea y valida movimientos globales contra bases del documento (si se proveen).
    class ProcesadorMovimientosGlobales
      def self.call(raw:, bases: nil)
        new(raw: raw, bases: bases).call
      end

      def initialize(raw:, bases: nil)
        @raw = raw
        @bases = bases
      end

      def call
        parseado = ParserMovimientos.call(raw)
        return parseado unless parseado[:success]

        validacion = ValidadorMovimientos.call(
          movimientos: parseado[:movimientos],
          bases: bases || {}
        )

        unless validacion[:success]
          return { success: false, errors: validacion[:errors] }
        end

        {
          success: true,
          movimientos: parseado[:movimientos]
        }
      end

      private

      attr_reader :raw, :bases
    end
  end
end

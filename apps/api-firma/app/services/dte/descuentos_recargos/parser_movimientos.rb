# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Parsea descuentos_recargos_globales del request JSON.
    class ParserMovimientos
      include Constants

      CAMPOS_REQUERIDOS = %i[tipo_movimiento tipo_valor valor aplica_sobre].freeze

      def self.call(raw)
        new(raw).call
      end

      def initialize(raw)
        @raw = raw
      end

      def call
        return { success: true, movimientos: [] } if raw.nil?

        unless raw.is_a?(Array)
          return {
            success: false,
            errors: ['descuentos_recargos_globales debe ser un arreglo']
          }
        end

        if raw.size > MAX_MOVIMIENTOS_GLOBALES
          return {
            success: false,
            errors: ["Máximo #{MAX_MOVIMIENTOS_GLOBALES} movimientos globales"]
          }
        end

        errores = []
        movimientos = raw.each_with_index.map do |entry, index|
          hash = normalizar_entrada(entry)
          unless hash.is_a?(Hash)
            errores << "descuentos_recargos_globales[#{index}]: debe ser un objeto"
            next
          end

          faltantes = CAMPOS_REQUERIDOS.reject do |campo|
            valor = hash[campo] || hash[campo.to_s]
            !valor.nil? && valor.to_s.strip != ''
          end

          if faltantes.any?
            errores << "descuentos_recargos_globales[#{index}]: faltan #{faltantes.join(', ')}"
            next
          end

          MovimientoGlobal.from_hash(hash, nro_linea: index + 1, orden: index + 1)
        end.compact

        if errores.any?
          { success: false, errors: errores }
        else
          { success: true, movimientos: movimientos }
        end
      end

      private

      attr_reader :raw

      # ActionController::Parameters (Rails) no es Hash pero sí hash-like.
      def normalizar_entrada(entry)
        return entry if entry.is_a?(Hash)
        return entry.to_unsafe_h if entry.respond_to?(:to_unsafe_h)
        return entry.to_h if entry.respond_to?(:to_h)

        entry
      end
    end
  end
end

# frozen_string_literal: true

module Dte
  module Referencias
    # Parsea referencias[] del request JSON y asigna nro_linea/orden correlativos.
    class Normalizador
      include Constants

      def self.call(raw)
        new(raw).call
      end

      def initialize(raw)
        @raw = raw
      end

      def call
        return { success: true, referencias: [] } if raw.nil?

        unless raw.is_a?(Array)
          return {
            success: false,
            errors: ['referencias debe ser un arreglo']
          }
        end

        if raw.size > MAX_REFERENCIAS
          return {
            success: false,
            errors: ["Máximo #{MAX_REFERENCIAS} referencias por documento"]
          }
        end

        errores = []
        referencias = raw.each_with_index.map do |entry, index|
          hash = normalizar_entrada(entry)
          unless hash.is_a?(Hash)
            errores << "referencias[#{index}]: debe ser un objeto"
            next
          end

          referencia = construir_referencia(hash, index)
          if referencia[:_error]
            errores << "referencias[#{index}]: #{referencia[:_error]}"
            next
          end

          referencia.except(:_error)
        end.compact

        if errores.any?
          { success: false, errors: errores }
        else
          { success: true, referencias: referencias }
        end
      end

      private

      attr_reader :raw

      def construir_referencia(hash, index)
        faltantes = CAMPOS_REQUERIDOS.reject { |campo| presente?(hash, campo) }
        if faltantes.any?
          return { _error: "faltan #{faltantes.join(', ')}" }
        end

        nro_linea = leer_entero(hash, :nro_linea)
        if !nro_linea.nil? && nro_linea != index + 1
          return { _error: 'nro_linea debe ser correlativo desde 1' }
        end

        {
          nro_linea: index + 1,
          orden: index + 1,
          tipo_documento_referencia: leer_string(hash, :tipo_documento_referencia).to_s.strip,
          folio_referencia: leer_string(hash, :folio_referencia).to_s.strip,
          fecha_referencia: leer_string(hash, :fecha_referencia).to_s.strip,
          codigo_referencia: leer_codigo_referencia(hash),
          razon_referencia: leer_string_opcional(hash, :razon_referencia),
          documento_emitido_origen_id: leer_entero_opcional(hash, :documento_emitido_origen_id)
        }
      end

      def leer_codigo_referencia(hash)
        valor = leer_valor(hash, :codigo_referencia)
        return nil if valor.nil? || valor.to_s.strip == ''

        valor.to_i
      end

      def leer_entero_opcional(hash, campo)
        valor = leer_valor(hash, campo)
        return nil if valor.nil? || valor.to_s.strip == ''

        valor.to_i
      end

      def leer_string_opcional(hash, campo)
        valor = leer_string(hash, campo).strip
        valor.empty? ? nil : valor
      end

      def leer_string(hash, campo)
        leer_valor(hash, campo).to_s
      end

      def leer_entero(hash, campo)
        valor = leer_valor(hash, campo)
        return nil if valor.nil? || valor.to_s.strip == ''

        valor.to_i
      end

      def presente?(hash, campo)
        valor = leer_valor(hash, campo)
        !valor.nil? && valor.to_s.strip != ''
      end

      def leer_valor(hash, campo)
        claves = ALIAS_CAMPOS.fetch(campo, [campo])
        claves.each do |clave|
          valor = hash[clave] || hash[clave.to_s]
          return valor unless valor.nil?
        end
        nil
      end

      def normalizar_entrada(entry)
        return entry if entry.is_a?(Hash)
        return entry.to_unsafe_h if entry.respond_to?(:to_unsafe_h)
        return entry.to_h if entry.respond_to?(:to_h)

        entry
      end
    end
  end
end

# frozen_string_literal: true

require 'date'

module Dte
  module Referencias
    # Valida referencias[] contra catálogo SII y reglas por tipo de emisión.
    class Validador
      include Constants

      TIPOS_CON_COD_REF_OBLIGATORIO = %w[56 61].freeze

      def self.call(raw:, tipo_documento_emision:, catalogo: nil, empresa_id: nil)
        new(
          raw: raw,
          tipo_documento_emision: tipo_documento_emision,
          catalogo: catalogo,
          empresa_id: empresa_id
        ).call
      end

      def initialize(raw:, tipo_documento_emision:, catalogo: nil, empresa_id: nil)
        @raw = raw
        @tipo_documento_emision = tipo_documento_emision.to_s
        @catalogo = catalogo
        @empresa_id = empresa_id
      end

      def call
        return { success: true, referencias: [] } if raw.nil?

        parseo = Normalizador.call(raw)
        return parseo unless parseo[:success]

        referencias = parseo[:referencias]
        errores = []

        referencias.each_with_index do |referencia, index|
          errores.concat(validar_referencia(referencia, index))
        end

        if errores.empty?
          {
            success: true,
            referencias: referencias.map { |referencia| enriquecer_referencia(referencia) }
          }
        else
          { success: false, errors: errores }
        end
      end

      private

      attr_reader :raw, :tipo_documento_emision, :catalogo, :empresa_id

      def validar_referencia(referencia, index)
        prefijo = "referencias[#{index}]"
        errores = []

        tipo_catalogo = catalogo_por_codigo[referencia[:tipo_documento_referencia]]
        unless tipo_catalogo
          errores << "#{prefijo}: tipo_documento_referencia no está en el catálogo activo"
          return errores
        end

        if tipo_catalogo.requiere_folio && referencia[:folio_referencia].to_s.strip.empty?
          errores << "#{prefijo}: folio_referencia es requerido"
        elsif referencia[:folio_referencia].to_s.length > MAX_FOLIO
          errores << "#{prefijo}: folio_referencia no puede superar #{MAX_FOLIO} caracteres"
        end

        if tipo_catalogo.requiere_fecha
          errores.concat(validar_fecha(referencia[:fecha_referencia], prefijo))
        end

        razon = referencia[:razon_referencia]
        if !razon.nil? && !razon.to_s.empty? && razon.to_s.length > MAX_RAZON
          errores << "#{prefijo}: razon_referencia no puede superar #{MAX_RAZON} caracteres"
        end

        errores.concat(validar_codigo_referencia(referencia, tipo_catalogo, prefijo))
        errores.concat(validar_documento_origen(referencia, prefijo))

        errores
      end

      def validar_documento_origen(referencia, prefijo)
        origen_id = referencia[:documento_emitido_origen_id]
        return [] if origen_id.nil?

        if origen_id.to_i <= 0
          return ["#{prefijo}: documento_emitido_origen_id debe ser un entero positivo"]
        end

        return [] if empresa_id.nil? || empresa_id.to_s.strip.empty?

        DocumentoOrigen.validar_vinculo(
          referencia: referencia,
          empresa_id: empresa_id,
          prefijo: prefijo
        )
      end

      def validar_fecha(fecha, prefijo)
        return ["#{prefijo}: fecha_referencia es requerida"] if fecha.nil? || fecha.to_s.strip.empty?

        Date.iso8601(fecha)
        []
      rescue ArgumentError
        ["#{prefijo}: fecha_referencia debe tener formato YYYY-MM-DD"]
      end

      def validar_codigo_referencia(referencia, tipo_catalogo, prefijo)
        codigo = referencia[:codigo_referencia]

        if codigo_referencia_obligatorio?
          if codigo.nil?
            return ["#{prefijo}: codigo_referencia es obligatorio para tipo_documento #{tipo_documento_emision}"]
          end
        elsif codigo.nil?
          return []
        end

        unless CODIGOS_REFERENCIA.include?(codigo)
          return ["#{prefijo}: codigo_referencia debe estar entre 1 y 4"]
        end

        if !tipo_catalogo.permite_codigo_referencia && !codigo.nil?
          return ["#{prefijo}: codigo_referencia no aplica para TpoDocRef #{tipo_catalogo.codigo_sii}"]
        end

        []
      end

      def codigo_referencia_obligatorio?
        TIPOS_CON_COD_REF_OBLIGATORIO.include?(tipo_documento_emision)
      end

      def enriquecer_referencia(referencia)
        tipo_catalogo = catalogo_por_codigo.fetch(referencia[:tipo_documento_referencia])

        referencia.merge(
          tipo_referencia_documento_id: tipo_catalogo.id,
          fecha_referencia: Date.iso8601(referencia[:fecha_referencia])
        )
      end

      def catalogo_por_codigo
        @catalogo_por_codigo ||= begin
          if catalogo.is_a?(Hash)
            catalogo
          elsif catalogo
            catalogo.each_with_object({}) { |tipo, mapa| mapa[tipo.codigo_sii] = tipo }
          else
            TipoReferenciaDocumento.activos.each_with_object({}) do |tipo, mapa|
              mapa[tipo.codigo_sii] = tipo
            end
          end
        end
      end
    end
  end
end

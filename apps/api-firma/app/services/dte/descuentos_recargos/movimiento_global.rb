# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Movimiento de descuento/recargo global tal como llega del request o persistencia.
    class MovimientoGlobal
      include Constants

      attr_reader :tipo_movimiento, :glosa, :tipo_valor, :valor, :aplica_sobre, :nro_linea, :orden
      attr_accessor :monto_calculado

      def self.from_hash(hash, nro_linea: nil, orden: nil)
        new(
          tipo_movimiento: hash[:tipo_movimiento] || hash['tipo_movimiento'],
          glosa: hash[:glosa] || hash['glosa'],
          tipo_valor: hash[:tipo_valor] || hash['tipo_valor'],
          valor: hash[:valor] || hash['valor'],
          aplica_sobre: hash[:aplica_sobre] || hash['aplica_sobre'],
          nro_linea: nro_linea || hash[:nro_linea] || hash['nro_linea'],
          orden: orden || hash[:orden] || hash['orden']
        )
      end

      def initialize(tipo_movimiento:, glosa:, tipo_valor:, valor:, aplica_sobre:, nro_linea: nil, orden: nil)
        @tipo_movimiento = tipo_movimiento.to_s.upcase
        @glosa = glosa.to_s.strip
        @tipo_valor = normalizar_tipo_valor(tipo_valor)
        @valor = valor.to_f
        @aplica_sobre = aplica_sobre.to_s.upcase
        @nro_linea = nro_linea
        @orden = orden
        @monto_calculado = nil
      end

      def descuento?
        tipo_movimiento == TPO_MOV_DESCUENTO
      end

      def recargo?
        tipo_movimiento == TPO_MOV_RECARGO
      end

      def porcentaje?
        tipo_valor == TIPO_VALOR_PORCENTAJE
      end

      def monto_fijo?
        tipo_valor == TIPO_VALOR_MONTO
      end

      def glosa_para_xml
        return glosa if glosa && !glosa.empty?

        descuento? ? GLOSA_DESCUENTO_DEFAULT : GLOSA_RECARGO_DEFAULT
      end

      def xml_tpo_valor
        porcentaje? ? XML_TPO_VALOR_PORCENTAJE : XML_TPO_VALOR_MONTO
      end

      def xml_ind_exe_dr
        case aplica_sobre
        when APLICA_SOBRE_EXENTO then IND_EXE_EXENTO
        when APLICA_SOBRE_NO_FACTURABLE then IND_EXE_NO_FACTURABLE
        end
      end

      def to_h
        {
          nro_linea: nro_linea,
          tipo_movimiento: tipo_movimiento,
          glosa: glosa_para_xml,
          tipo_valor: tipo_valor,
          valor: valor,
          aplica_sobre: aplica_sobre,
          monto_calculado: monto_calculado,
          orden: orden
        }
      end

      private

      def normalizar_tipo_valor(valor)
        raw = valor.to_s.upcase
        return TIPO_VALOR_PORCENTAJE if [TIPO_VALOR_PORCENTAJE, '%', 'PORCENTAJE', 'PCT'].include?(raw)
        return TIPO_VALOR_MONTO if [TIPO_VALOR_MONTO, '$', 'MONTO', 'FIJO'].include?(raw)

        raw
      end
    end
  end
end

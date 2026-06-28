# frozen_string_literal: true

module Dte
  module DescuentosRecargos
  # Vocabulario alineado con Formato DTE SII (Descuentos y Recargos Globales).
    module Constants
      TPO_MOV_DESCUENTO = 'D'
      TPO_MOV_RECARGO = 'R'
      TPOS_MOVIMIENTO = [TPO_MOV_DESCUENTO, TPO_MOV_RECARGO].freeze

      TIPO_VALOR_PORCENTAJE = 'PORCENTAJE'
      TIPO_VALOR_MONTO = 'MONTO'
      TIPOS_VALOR = [TIPO_VALOR_PORCENTAJE, TIPO_VALOR_MONTO].freeze

      # Valores en XML (<TpoValor>)
      XML_TPO_VALOR_PORCENTAJE = '%'
      XML_TPO_VALOR_MONTO = '$'

      APLICA_SOBRE_AFECTO = 'AFECTO'
      APLICA_SOBRE_EXENTO = 'EXENTO_NO_AFECTO'
      APLICA_SOBRE_NO_FACTURABLE = 'NO_FACTURABLE'
      AMBITOS_MONTO = [
        APLICA_SOBRE_AFECTO,
        APLICA_SOBRE_EXENTO,
        APLICA_SOBRE_NO_FACTURABLE
      ].freeze

      # <IndExeDR> en XML según ámbito
      IND_EXE_EXENTO = 1
      IND_EXE_NO_FACTURABLE = 2

      MAX_MOVIMIENTOS_GLOBALES = 20

      GLOSA_DESCUENTO_DEFAULT = 'Descuento comercial'
      GLOSA_RECARGO_DEFAULT = 'Recargo'
    end
  end
end

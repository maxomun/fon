# frozen_string_literal: true

module Dte
  module DescuentosRecargos
    # Integra líneas + movimientos globales para una página/documento del pipeline DTE.
    class IntegradorPagina
      def self.call(items_pagina:, movimientos_globales_raw: nil)
        new(items_pagina: items_pagina, movimientos_globales_raw: movimientos_globales_raw).call
      end

      def initialize(items_pagina:, movimientos_globales_raw: nil)
        @items_pagina = items_pagina
        @movimientos_globales_raw = movimientos_globales_raw
      end

      def call
        globales = ProcesadorMovimientosGlobales.call(
          raw: movimientos_globales_raw,
          bases: BasesDocumento.desde_items(items_pagina)
        )
        return globales unless globales[:success]

        calculo = CalculadorDocumento.call(
          items: items_pagina,
          movimientos_globales: globales[:movimientos]
        )
        return calculo unless calculo[:success]

        {
          success: true,
          totales: calculo[:totales].to_generador_xml,
          descuentos_recargos_globales: calculo[:movimientos_globales],
          subtotales: calculo[:subtotales]
        }
      end

      private

      attr_reader :items_pagina, :movimientos_globales_raw
    end
  end
end

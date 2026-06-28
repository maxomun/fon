# frozen_string_literal: true

module DteDescuentosRecargosParams
  extend ActiveSupport::Concern

  private

  def descuentos_recargos_globales_raw
    params[:descuentos_recargos_globales] || params['descuentos_recargos_globales']
  end

  def errores_estructura_descuentos_recargos_globales
    return [] if descuentos_recargos_globales_raw.nil?

    resultado = Dte::DescuentosRecargos::ParserMovimientos.call(descuentos_recargos_globales_raw)
    resultado[:success] ? [] : resultado[:errors]
  end

  def calcular_pagina_dte(items_pagina:, movimientos_globales_raw: nil)
    Dte::DescuentosRecargos::IntegradorPagina.call(
      items_pagina: items_pagina,
      movimientos_globales_raw: movimientos_globales_raw.nil? ? descuentos_recargos_globales_raw : movimientos_globales_raw
    )
  end

  def calcular_documento_con_globales(items_preparados:)
    resultado = calcular_pagina_dte(items_pagina: items_preparados)
    return resultado unless resultado[:success]

    {
      success: true,
      subtotales: resultado[:subtotales],
      totales: totales_para_respuesta(resultado[:totales]),
      descuentos_recargos_globales: resultado[:descuentos_recargos_globales]
    }
  end

  def totales_para_respuesta(totales_hash)
    totales_hash.merge(
      neto_no_facturable: totales_hash[:neto_no_facturable] || 0
    )
  end

  def payload_calcular_totales_dte(data)
    {
      subtotales: data[:subtotales],
      totales: data[:totales],
      descuentos_recargos_globales: data[:descuentos_recargos_globales]
    }
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 5: IntegradorPagina en pipeline (sin Rails).
# Uso: ruby script/verify_descuentos_recargos_f5_pipeline.rb

ROOT = File.expand_path('..', __dir__)
SERVICES = File.join(ROOT, 'app/services/dte/descuentos_recargos')

%w[
  constants.rb
  error.rb
  clasificacion_monto.rb
  movimiento_global.rb
  linea_calculada.rb
  totales_documento.rb
  validador_movimientos.rb
  bases_documento.rb
  parser_movimientos.rb
  procesador_movimientos_globales.rb
  calculador_documento.rb
  integrador_pagina.rb
].each { |file| require File.join(SERVICES, file) }

module VerifyF5Pipeline
  module_function

  C = Dte::DescuentosRecargos::Constants

  def run!
    puts '=== Verificación F5: pipeline totales con globales ==='
    failures = 0
    failures += 1 unless caso_sin_globales_regresion
    failures += 1 unless caso_4919151_4_pipeline
    failures += 1 unless caso_pagina_incluye_movimientos
    failures += 1 unless caso_dos_paginas_globales_independientes

    if failures.zero?
      puts "\n✅ F5 pipeline: todos los casos pasaron (#{4} escenarios)"
      exit 0
    else
      puts "\n❌ F5 pipeline: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def item_afecto(cantidad:, precio:, pagina: 1)
    neto = cantidad * precio
    {
      pagina: pagina,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: neto,
      ambito_monto: C::APLICA_SOBRE_AFECTO,
      afecto: true,
      impuestos: [{ codigo: 'IVA', tasa: 19 }]
    }
  end

  def item_exento(cantidad:, precio:, pagina: 1)
    {
      pagina: pagina,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: cantidad * precio,
      ambito_monto: C::APLICA_SOBRE_EXENTO,
      afecto: false,
      impuestos: []
    }
  end

  def integrar(items, movimientos_raw = nil)
    Dte::DescuentosRecargos::IntegradorPagina.call(
      items_pagina: items,
      movimientos_globales_raw: movimientos_raw
    )
  end

  def simular_paginas(all_items, paginas_meta, movimientos_raw = nil)
    paginas_meta.map do |pg|
      items_pagina = all_items.select { |i| i[:pagina] == pg[:pagina] }
      resultado = integrar(items_pagina, movimientos_raw)
      return resultado unless resultado[:success]

      {
        numero: pg[:pagina],
        folio: pg[:folio],
        items: items_pagina,
        totales: resultado[:totales],
        descuentos_recargos_globales: resultado[:descuentos_recargos_globales]
      }
    end
  end

  def caso_sin_globales_regresion
    puts "\n[K1] Sin globales — regresión pipeline"
    items = [
      item_afecto(cantidad: 2, precio: 10_000, pagina: 1),
      item_exento(cantidad: 1, precio: 5_000, pagina: 1)
    ]
    r = integrar(items)
    return false unless r[:success]

    t = r[:totales]
    ok = true
    ok &&= assert_eq(t[:neto_afecto], 20_000, 'neto afecto')
    ok &&= assert_eq(t[:neto_exento], 5_000, 'neto exento')
    ok &&= assert_eq(t[:iva], 3_800, 'iva')
    ok &&= assert_eq(t[:total], 28_800, 'total')
    ok &&= assert_eq(r[:descuentos_recargos_globales], [], 'sin movimientos globales')
    ok ? (puts '  OK'; true) : false
  end

  def caso_4919151_4_pipeline
    puts "\n[K2] Caso 4919151-4 vía IntegradorPagina"
    items = [
      item_afecto(cantidad: 567, precio: 7_872, pagina: 1),
      item_afecto(cantidad: 240, precio: 9_871, pagina: 1),
      item_exento(cantidad: 2, precio: 6_863, pagina: 1)
    ]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 30,
      aplica_sobre: 'AFECTO'
    }]
    r = integrar(items, movimientos)
    return false unless r[:success]

    t = r[:totales]
    ok = true
    ok &&= assert_eq(t[:neto_afecto], 4_782_725, 'neto afecto')
    ok &&= assert_eq(t[:iva], 908_717, 'iva')
    ok &&= assert_eq(t[:total], 5_705_168, 'total')
    ok ? (puts '  OK'; true) : false
  end

  def caso_pagina_incluye_movimientos
    puts "\n[K3] Página incluye descuentos_recargos_globales calculados"
    items = [item_afecto(cantidad: 1, precio: 100_000, pagina: 1)]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 10,
      aplica_sobre: 'AFECTO'
    }]
    paginas = simular_paginas(items, [{ pagina: 1, folio: 1 }], movimientos)
    return false if paginas.is_a?(Hash) && paginas[:success] == false

    pg = paginas.first
    ok = pg[:descuentos_recargos_globales].size == 1 &&
         pg[:descuentos_recargos_globales].first[:monto_calculado] == 10_000
    ok ? (puts '  OK'; true) : (puts '  FAIL movimientos en página'; false)
  end

  def caso_dos_paginas_globales_independientes
    puts "\n[K4] Dos páginas — global 10% afecto en cada una"
    items = [
      item_afecto(cantidad: 1, precio: 100_000, pagina: 1),
      item_afecto(cantidad: 1, precio: 50_000, pagina: 2)
    ]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 10,
      aplica_sobre: 'AFECTO'
    }]
    paginas = simular_paginas(items, [{ pagina: 1, folio: 1 }, { pagina: 2, folio: 2 }], movimientos)
    return false if paginas.is_a?(Hash) && paginas[:success] == false

    ok = true
    ok &&= assert_eq(paginas[0][:totales][:neto_afecto], 90_000, 'página 1 neto')
    ok &&= assert_eq(paginas[1][:totales][:neto_afecto], 45_000, 'página 2 neto')
    ok ? (puts '  OK'; true) : false
  end
end

VerifyF5Pipeline.run!

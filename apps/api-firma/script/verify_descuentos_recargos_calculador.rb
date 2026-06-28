#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación manual del calculador (Fase 3).
# Uso:
#   bundle exec ruby script/verify_descuentos_recargos_calculador.rb   (con Rails)
#   ruby script/verify_descuentos_recargos_standalone.rb             (sin Rails)

require_relative '../config/environment' unless defined?(Dte::DescuentosRecargos)

module VerifyDescuentosRecargos
  module_function

  def run!
    puts '=== Verificación Dte::DescuentosRecargos::CalculadorDocumento ==='
    failures = 0
    failures += 1 unless caso_sin_globales
    failures += 1 unless caso_4919151_4
    failures += 1 unless caso_dual_afecto_exento
    failures += 1 unless caso_recargo_afecto
    failures += 1 unless caso_descuento_excede_base
    failures += 1 unless caso_max_movimientos

    if failures.zero?
      puts "\n✅ Todos los casos pasaron (#{6} escenarios)"
      exit 0
    else
      puts "\n❌ #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def assert_ok(result, label)
    return true if result[:success]

    puts "  FAIL #{label}: #{result[:error]}"
    false
  end

  def assert_fail(result, label)
    return true unless result[:success]

    puts "  FAIL #{label}: se esperaba error"
    false
  end

  def item_afecto(cantidad:, precio:, descuento_pct: 0)
    {
      cantidad: cantidad,
      precio_unitario: precio,
      descuento_pct: descuento_pct,
      afecto: true,
      impuestos: [{ codigo: 'IVA', nombre: 'IVA', tasa: 19 }]
    }
  end

  def item_exento(cantidad:, precio:)
    {
      cantidad: cantidad,
      precio_unitario: precio,
      afecto: false,
      impuestos: []
    }
  end

  def calc(items, movimientos = [])
    Dte::DescuentosRecargos::CalculadorDocumento.call(
      items: items,
      movimientos_globales: movimientos
    )
  end

  def caso_sin_globales
    puts "\n[Caso A] Sin globales (regresión)"
    items = [
      item_afecto(cantidad: 2, precio: 10_000, descuento_pct: 10),
      item_exento(cantidad: 1, precio: 5_000)
    ]
    result = calc(items)
    return false unless assert_ok(result, 'A')

    t = result[:totales]
    ok = true
    ok &&= assert_eq(t.neto_afecto, 18_000, 'neto afecto')      # 20000 - 10%
    ok &&= assert_eq(t.neto_exento, 5_000, 'neto exento')
    ok &&= assert_eq(t.iva, 3_420, 'iva')                         # 18000 * 19%
    ok &&= assert_eq(t.total, 26_420, 'total')
    ok ? (puts '  OK'; true) : false
  end

  def caso_4919151_4
    puts "\n[Caso B] 4919151-4 — descuento global 30% solo afectos"
    items = [
      item_afecto(cantidad: 567, precio: 7_872),
      item_afecto(cantidad: 240, precio: 9_871),
      item_exento(cantidad: 2, precio: 6_863)
    ]
    movimientos = [
      {
        tipo_movimiento: 'D',
        glosa: 'Descuento global ítems afectos',
        tipo_valor: 'PORCENTAJE',
        valor: 30,
        aplica_sobre: 'AFECTO'
      }
    ]
    result = calc(items, movimientos)
    return false unless assert_ok(result, 'B')

    t = result[:totales]
    sub_afecto = (567 * 7_872) + (240 * 9_871) # 6_832_464
    desc_global = (sub_afecto * 0.3).to_i      # 2_049_739
    neto_afecto = sub_afecto - desc_global     # 4_782_725
    iva = (neto_afecto * 0.19).to_i            # 908_717
    exento = 2 * 6_863                         # 13_726
    total = neto_afecto + iva + exento         # 5_705_168

    ok = true
    ok &&= assert_eq(t.subtotal_afecto, sub_afecto, 'subtotal afecto')
    ok &&= assert_eq(t.neto_afecto, neto_afecto, 'neto afecto post-global')
    ok &&= assert_eq(t.neto_exento, exento, 'exento sin tocar')
    ok &&= assert_eq(t.iva, iva, 'iva')
    ok &&= assert_eq(t.total, total, 'total')
    ok &&= assert_eq(result[:movimientos_globales].first[:monto_calculado], desc_global, 'monto global')
    ok ? (puts '  OK'; true) : false
  end

  def caso_dual_afecto_exento
    puts "\n[Caso C] §8 — 10% afecto + 10% exento (2 movimientos)"
    items = [
      item_afecto(cantidad: 10, precio: 10_000),
      item_exento(cantidad: 5, precio: 10_000)
    ]
    movimientos = [
      {
        tipo_movimiento: 'D',
        glosa: 'Descuento sobre productos afectos',
        tipo_valor: 'PORCENTAJE',
        valor: 10,
        aplica_sobre: 'AFECTO'
      },
      {
        tipo_movimiento: 'D',
        glosa: 'Descuento sobre productos exentos',
        tipo_valor: 'PORCENTAJE',
        valor: 10,
        aplica_sobre: 'EXENTO_NO_AFECTO'
      }
    ]
    result = calc(items, movimientos)
    return false unless assert_ok(result, 'C')

    t = result[:totales]
    ok = true
    ok &&= assert_eq(t.neto_afecto, 90_000, 'neto afecto')
    ok &&= assert_eq(t.neto_exento, 45_000, 'neto exento')
    ok &&= assert_eq(t.iva, 17_100, 'iva')
    ok &&= assert_eq(result[:movimientos_globales].size, 2, 'cantidad movimientos')
    ok ? (puts '  OK'; true) : false
  end

  def caso_recargo_afecto
    puts "\n[Caso D] Recargo 5% sobre afectos"
    items = [item_afecto(cantidad: 1, precio: 100_000)]
    movimientos = [
      {
        tipo_movimiento: 'R',
        glosa: 'Recargo comercial',
        tipo_valor: 'PORCENTAJE',
        valor: 5,
        aplica_sobre: 'AFECTO'
      }
    ]
    result = calc(items, movimientos)
    return false unless assert_ok(result, 'D')

    t = result[:totales]
    ok = true
    ok &&= assert_eq(t.neto_afecto, 105_000, 'neto afecto')
    ok &&= assert_eq(t.iva, 19_950, 'iva')
    ok ? (puts '  OK'; true) : false
  end

  def caso_descuento_excede_base
    puts "\n[Caso E] Descuento mayor que base → error"
    items = [item_afecto(cantidad: 1, precio: 1_000)]
    movimientos = [
      {
        tipo_movimiento: 'D',
        tipo_valor: 'MONTO',
        valor: 2_000,
        aplica_sobre: 'AFECTO'
      }
    ]
    result = calc(items, movimientos)
    assert_fail(result, 'E') ? (puts '  OK'; true) : false
  end

  def caso_max_movimientos
    puts "\n[Caso F] Más de 20 movimientos → error"
    items = [item_afecto(cantidad: 1, precio: 1_000_000)]
    movimientos = Array.new(21) do
      {
        tipo_movimiento: 'D',
        tipo_valor: 'MONTO',
        valor: 1,
        aplica_sobre: 'AFECTO'
      }
    end
    result = calc(items, movimientos)
    assert_fail(result, 'F') ? (puts '  OK'; true) : false
  end
end

VerifyDescuentosRecargos.run!

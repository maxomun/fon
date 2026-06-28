#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 6: persistencia de descuentos/recargos globales (sin Rails).
# Uso: ruby script/verify_descuentos_recargos_f6_persistencia.rb

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

module VerifyF6Persistencia
  module_function

  C = Dte::DescuentosRecargos::Constants

  def run!
    puts '=== Verificación F6: persistencia movimientos globales ==='
    failures = 0
    failures += 1 unless caso_atributos_desde_integrador
    failures += 1 unless caso_sin_globales_no_crea_filas
    failures += 1 unless caso_4919151_4_movimiento
    failures += 1 unless caso_dos_movimientos_orden

    if failures.zero?
      puts "\n✅ F6 persistencia: todos los casos pasaron (#{4} escenarios)"
      exit 0
    else
      puts "\n❌ F6 persistencia: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  # Réplica de DocumentoDescuentoRecargoGlobal.crear_desde_hash! sin ActiveRecord.
  def atributos_persistencia(movimiento)
    {
      nro_linea: movimiento[:nro_linea],
      tipo_movimiento: movimiento[:tipo_movimiento],
      glosa: movimiento[:glosa],
      tipo_valor: movimiento[:tipo_valor],
      valor: movimiento[:valor],
      aplica_sobre: movimiento[:aplica_sobre],
      monto_calculado: movimiento[:monto_calculado],
      orden: movimiento[:orden]
    }
  end

  def integrar(items, movimientos_raw = nil)
    Dte::DescuentosRecargos::IntegradorPagina.call(
      items_pagina: items,
      movimientos_globales_raw: movimientos_raw
    )
  end

  def item_afecto(cantidad:, precio:)
    {
      pagina: 1,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: cantidad * precio,
      ambito_monto: C::APLICA_SOBRE_AFECTO,
      afecto: true,
      impuestos: [{ codigo: 'IVA', tasa: 19 }]
    }
  end

  def item_exento(cantidad:, precio:)
    {
      pagina: 1,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: cantidad * precio,
      ambito_monto: C::APLICA_SOBRE_EXENTO,
      afecto: false,
      impuestos: []
    }
  end

  def caso_atributos_desde_integrador
    puts "\n[P1] Atributos de persistencia desde IntegradorPagina"
    items = [item_afecto(cantidad: 1, precio: 100_000)]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 10,
      aplica_sobre: 'AFECTO'
    }]
    r = integrar(items, movimientos)
    return false unless r[:success]

    attrs = atributos_persistencia(r[:descuentos_recargos_globales].first)
    ok = true
    ok &&= assert_eq(attrs[:nro_linea], 1, 'nro_linea')
    ok &&= assert_eq(attrs[:tipo_movimiento], 'D', 'tipo_movimiento')
    ok &&= assert_eq(attrs[:glosa], 'Descuento comercial', 'glosa default')
    ok &&= assert_eq(attrs[:tipo_valor], 'PORCENTAJE', 'tipo_valor')
    ok &&= assert_eq(attrs[:valor], 10.0, 'valor')
    ok &&= assert_eq(attrs[:aplica_sobre], 'AFECTO', 'aplica_sobre')
    ok &&= assert_eq(attrs[:monto_calculado], 10_000, 'monto_calculado')
    ok &&= assert_eq(attrs[:orden], 1, 'orden')
    ok ? (puts '  OK'; true) : false
  end

  def caso_sin_globales_no_crea_filas
    puts "\n[P2] Sin globales — arreglo vacío (no persistir filas)"
    items = [item_afecto(cantidad: 1, precio: 50_000)]
    r = integrar(items)
    return false unless r[:success]

    ok = r[:descuentos_recargos_globales].empty?
    ok ? (puts '  OK'; true) : (puts '  FAIL debería ser []'; false)
  end

  def caso_4919151_4_movimiento
    puts "\n[P3] Caso 4919151-4 — un movimiento global afecto 30%"
    items = [
      item_afecto(cantidad: 567, precio: 7_872),
      item_afecto(cantidad: 240, precio: 9_871),
      item_exento(cantidad: 2, precio: 6_863)
    ]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 30,
      aplica_sobre: 'AFECTO'
    }]
    r = integrar(items, movimientos)
    return false unless r[:success]

    mov = r[:descuentos_recargos_globales].first
    ok = mov[:monto_calculado] == 2_049_739 &&
         mov[:aplica_sobre] == 'AFECTO' &&
         mov[:nro_linea] == 1
    ok ? (puts '  OK'; true) : (puts "  FAIL mov=#{mov.inspect}"; false)
  end

  def caso_dos_movimientos_orden
    puts "\n[P4] Dos movimientos — nro_linea y orden correlativos"
    items = [
      item_afecto(cantidad: 1, precio: 100_000),
      item_exento(cantidad: 1, precio: 50_000)
    ]
    movimientos = [
      { tipo_movimiento: 'D', tipo_valor: 'PORCENTAJE', valor: 10, aplica_sobre: 'AFECTO' },
      { tipo_movimiento: 'D', tipo_valor: 'PORCENTAJE', valor: 5, aplica_sobre: 'EXENTO_NO_AFECTO' }
    ]
    r = integrar(items, movimientos)
    return false unless r[:success]

    movs = r[:descuentos_recargos_globales]
    ok = movs.size == 2 &&
         movs[0][:nro_linea] == 1 && movs[0][:orden] == 1 &&
         movs[1][:nro_linea] == 2 && movs[1][:orden] == 2
    ok ? (puts '  OK'; true) : (puts "  FAIL movs=#{movs.inspect}"; false)
  end
end

VerifyF6Persistencia.run!

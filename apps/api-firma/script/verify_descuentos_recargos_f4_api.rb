#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 4: parser, validador y cálculo integrado (sin Rails).
# Uso: ruby script/verify_descuentos_recargos_f4_api.rb

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
].each { |file| require File.join(SERVICES, file) }

module VerifyF4Api
  module_function

  C = Dte::DescuentosRecargos::Constants

  def run!
    puts '=== Verificación F4: contrato API descuentos/recargos globales ==='
    failures = 0
    failures += 1 unless caso_parser_rechaza_no_array
    failures += 1 unless caso_parser_rechaza_campo_faltante
    failures += 1 unless caso_vacio_valido
    failures += 1 unless caso_parser_acepta_hash_like
    failures += 1 unless caso_4919151_4_integrado
    failures += 1 unless caso_tipo_movimiento_invalido
    failures += 1 unless caso_max_21_movimientos
    failures += 1 unless caso_descuento_monto_excede_base

    if failures.zero?
      puts "\n✅ F4 API: todos los casos pasaron (#{8} escenarios)"
      exit 0
    else
      puts "\n❌ F4 API: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_ok(result, label)
    return true if result[:success]

    puts "  FAIL #{label}: #{Array(result[:errors] || result[:error]).join('; ')}"
    false
  end

  def assert_fail(result, label)
    return true unless result[:success]

    puts "  FAIL #{label}: se esperaba error"
    false
  end

  def items_caso_4
    [
      {
        cantidad: 567,
        precio_unitario: 7_872,
        neto: 567 * 7_872,
        ambito_monto: C::APLICA_SOBRE_AFECTO,
        afecto: true,
        impuestos: [{ codigo: 'IVA', tasa: 19 }]
      },
      {
        cantidad: 240,
        precio_unitario: 9_871,
        neto: 240 * 9_871,
        ambito_monto: C::APLICA_SOBRE_AFECTO,
        afecto: true,
        impuestos: [{ codigo: 'IVA', tasa: 19 }]
      },
      {
        cantidad: 2,
        precio_unitario: 6_863,
        neto: 2 * 6_863,
        ambito_monto: C::APLICA_SOBRE_EXENTO,
        afecto: false,
        impuestos: []
      }
    ]
  end

  def calcular_integrado(items, movimientos_raw)
    bases = Dte::DescuentosRecargos::BasesDocumento.desde_items(items)
    globales = Dte::DescuentosRecargos::ProcesadorMovimientosGlobales.call(raw: movimientos_raw, bases: bases)
    return globales unless globales[:success]

    Dte::DescuentosRecargos::CalculadorDocumento.call(
      items: items,
      movimientos_globales: globales[:movimientos]
    )
  end

  def caso_parser_rechaza_no_array
    puts "\n[J1] Parser rechaza no-array"
    r = Dte::DescuentosRecargos::ParserMovimientos.call({ 'tipo_movimiento' => 'D' })
    assert_fail(r, 'J1') ? (puts '  OK'; true) : false
  end

  def caso_parser_rechaza_campo_faltante
    puts "\n[J2] Parser rechaza campo faltante"
    r = Dte::DescuentosRecargos::ParserMovimientos.call([{ 'tipo_movimiento' => 'D', 'valor' => 10 }])
    assert_fail(r, 'J2') ? (puts '  OK'; true) : false
  end

  def caso_parser_acepta_hash_like
    puts "\n[J3b] Parser acepta objetos hash-like (ActionController::Parameters)"
    entry = Class.new do
      def initialize(h)
        @h = h
      end

      def to_unsafe_h
        @h
      end
    end.new(
      'tipo_movimiento' => 'D',
      'tipo_valor' => 'PORCENTAJE',
      'valor' => 10,
      'aplica_sobre' => 'AFECTO'
    )
    r = Dte::DescuentosRecargos::ParserMovimientos.call([entry])
    assert_ok(r, 'J3b') && r[:movimientos].size == 1 ? (puts '  OK'; true) : false
  end

  def caso_vacio_valido
    puts "\n[J3] Arreglo vacío es válido"
    r = Dte::DescuentosRecargos::ProcesadorMovimientosGlobales.call(raw: [], bases: {})
    assert_ok(r, 'J3') ? (puts '  OK'; true) : false
  end

  def caso_4919151_4_integrado
    puts "\n[J4] Caso 4919151-4 — cálculo integrado"
    movimientos = [
      {
        tipo_movimiento: 'D',
        glosa: 'Descuento global ítems afectos',
        tipo_valor: 'PORCENTAJE',
        valor: 30,
        aplica_sobre: 'AFECTO'
      }
    ]
    r = calcular_integrado(items_caso_4, movimientos)
    return false unless assert_ok(r, 'J4')

    t = r[:totales]
    ok = t.neto_afecto == 4_782_725 && t.total == 5_705_168
    puts ok ? '  OK' : "  FAIL totales: neto_afecto=#{t.neto_afecto} total=#{t.total}"
    ok
  end

  def caso_tipo_movimiento_invalido
    puts "\n[J5] tipo_movimiento inválido"
    r = Dte::DescuentosRecargos::ProcesadorMovimientosGlobales.call(
      raw: [{
        tipo_movimiento: 'X',
        tipo_valor: 'PORCENTAJE',
        valor: 10,
        aplica_sobre: 'AFECTO'
      }],
      bases: { C::APLICA_SOBRE_AFECTO => 1000 }
    )
    assert_fail(r, 'J5') ? (puts '  OK'; true) : false
  end

  def caso_max_21_movimientos
    puts "\n[J6] Más de 20 movimientos"
    raw = Array.new(21) do
      {
        tipo_movimiento: 'D',
        tipo_valor: 'MONTO',
        valor: 1,
        aplica_sobre: 'AFECTO'
      }
    end
    r = Dte::DescuentosRecargos::ParserMovimientos.call(raw)
    assert_fail(r, 'J6') ? (puts '  OK'; true) : false
  end

  def caso_descuento_monto_excede_base
    puts "\n[J7] Descuento $ mayor que base"
    r = calcular_integrado(
      [{ neto: 1000, ambito_monto: C::APLICA_SOBRE_AFECTO, afecto: true, impuestos: [{ codigo: 'IVA', tasa: 19 }] }],
      [{
        tipo_movimiento: 'D',
        tipo_valor: 'MONTO',
        valor: 2000,
        aplica_sobre: 'AFECTO'
      }]
    )
    assert_fail(r, 'J7') ? (puts '  OK'; true) : false
  end
end

VerifyF4Api.run!

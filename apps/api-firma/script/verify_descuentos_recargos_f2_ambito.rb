#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 2: clasificación afecto / exento / no facturable.
# Uso: ruby script/verify_descuentos_recargos_f2_ambito.rb

ROOT = File.expand_path('..', __dir__)
SERVICES = File.join(ROOT, 'app/services/dte/descuentos_recargos')

%w[
  constants.rb
  clasificacion_monto.rb
  linea_calculada.rb
].each { |file| require File.join(SERVICES, file) }

module VerifyF2Ambito
  module_function

  C = Dte::DescuentosRecargos::Constants

  def run!
    puts '=== Verificación F2: clasificación de ámbito ==='
    failures = 0
    failures += 1 unless caso_derivar_afecto
    failures += 1 unless caso_derivar_exento
    failures += 1 unless caso_explicito_no_facturable
    failures += 1 unless caso_mixto_tres_ambitos
    failures += 1 unless caso_xml_ind_exe_exento

    if failures.zero?
      puts "\n✅ F2 ámbito: todos los casos pasaron (#{5} escenarios)"
      exit 0
    else
      puts "\n❌ F2 ámbito: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def clasificar(ambito_monto: nil, tiene_impuestos: false)
    Dte::DescuentosRecargos::ClasificacionMonto.new(
      ambito_monto: ambito_monto,
      tiene_impuestos: tiene_impuestos
    )
  end

  def caso_derivar_afecto
    puts "\n[H1] Producto con impuestos → AFECTO"
    c = clasificar(tiene_impuestos: true)
    assert_eq(c.ambito_monto, C::APLICA_SOBRE_AFECTO, 'ambito') ? (puts '  OK'; true) : false
  end

  def caso_derivar_exento
    puts "\n[H2] Producto sin impuestos → EXENTO_NO_AFECTO"
    c = clasificar(tiene_impuestos: false)
    assert_eq(c.ambito_monto, C::APLICA_SOBRE_EXENTO, 'ambito') ? (puts '  OK'; true) : false
  end

  def caso_explicito_no_facturable
    puts "\n[H3] Producto explícito NO_FACTURABLE"
    c = clasificar(ambito_monto: C::APLICA_SOBRE_NO_FACTURABLE, tiene_impuestos: false)
    ok = true
    ok &&= assert_eq(c.ambito_monto, C::APLICA_SOBRE_NO_FACTURABLE, 'ambito')
    ok &&= assert_eq(c.ind_exe_detalle, C::IND_EXE_NO_FACTURABLE, 'IndExe detalle')
    ok ? (puts '  OK'; true) : false
  end

  def caso_mixto_tres_ambitos
    puts "\n[H4] Mixto 4919151-3 — 2 afectos + 1 exento"
    items = [
      { cantidad: 1, precio_unitario: 100, ambito_monto: C::APLICA_SOBRE_AFECTO, afecto: true },
      { cantidad: 1, precio_unitario: 200, ambito_monto: C::APLICA_SOBRE_AFECTO, afecto: true },
      { cantidad: 1, precio_unitario: 300, ambito_monto: C::APLICA_SOBRE_EXENTO, afecto: false }
    ]

    neto_afecto = 0
    neto_exento = 0
    neto_no_facturable = 0

    items.each do |item|
      linea = Dte::DescuentosRecargos::LineaCalculada.from_item(item)
      case linea.ambito_monto
      when C::APLICA_SOBRE_AFECTO then neto_afecto += linea.monto_neto
      when C::APLICA_SOBRE_EXENTO then neto_exento += linea.monto_neto
      when C::APLICA_SOBRE_NO_FACTURABLE then neto_no_facturable += linea.monto_neto
      end
    end

    ok = true
    ok &&= assert_eq(neto_afecto, 300, 'neto afecto')
    ok &&= assert_eq(neto_exento, 300, 'neto exento')
    ok &&= assert_eq(neto_no_facturable, 0, 'neto no facturable')
    ok ? (puts '  OK'; true) : false
  end

  def caso_xml_ind_exe_exento
    puts "\n[H5] IndExe=1 para línea exenta"
    ind = Dte::DescuentosRecargos::ClasificacionMonto.desde_item(
      ambito_monto: C::APLICA_SOBRE_EXENTO,
      afecto: false
    ).ind_exe_detalle
    assert_eq(ind, C::IND_EXE_EXENTO, 'IndExe') ? (puts '  OK'; true) : false
  end
end

VerifyF2Ambito.run!

#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 1: descuento/recargo por línea (cálculo + XML).
# Uso: ruby script/verify_descuentos_recargos_f1_linea.rb

ROOT = File.expand_path('..', __dir__)
SERVICES = File.join(ROOT, 'app/services/dte/descuentos_recargos')

%w[
  constants.rb
  error.rb
  clasificacion_monto.rb
  linea_calculada.rb
].each { |file| require File.join(SERVICES, file) }

require File.join(ROOT, 'app/services/dte/generador_xml.rb')
require 'nokogiri'

# ActiveSupport no cargado en script standalone
unless ''.respond_to?(:present?)
  class String
    def present?
      !empty?
    end
  end

  class NilClass
    def present?
      false
    end
  end
end

module VerifyF1Linea
  module_function

  def run!
    puts '=== Verificación F1: descuento/recargo por línea ==='
    failures = 0
    failures += 1 unless caso_descuento_pct_linea
    failures += 1 unless caso_recargo_pct_linea
    failures += 1 unless caso_recargo_monto_linea
    failures += 1 unless caso_descuento_y_recargo_linea
    failures += 1 unless caso_xml_recargo_monto

    if failures.zero?
      puts "\n✅ F1 línea: todos los casos pasaron (#{5} escenarios)"
      exit 0
    else
      puts "\n❌ F1 línea: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def calc_linea(attrs)
    Dte::DescuentosRecargos::LineaCalculada.from_item(attrs)
  end

  def caso_descuento_pct_linea
    puts "\n[G1] Descuento 10% por línea (4919151-2)"
    linea = calc_linea(
      cantidad: 2,
      precio_unitario: 10_000,
      descuento_pct: 10,
      afecto: true
    )
    ok = true
    ok &&= assert_eq(linea.monto_bruto, 20_000, 'bruto')
    ok &&= assert_eq(linea.descuento_linea, 2_000, 'descuento')
    ok &&= assert_eq(linea.monto_neto, 18_000, 'neto')
    ok ? (puts '  OK'; true) : false
  end

  def caso_recargo_pct_linea
    puts "\n[G2] Recargo 5% por línea"
    linea = calc_linea(
      cantidad: 1,
      precio_unitario: 100_000,
      recargo_pct: 5,
      afecto: true
    )
    ok = true
    ok &&= assert_eq(linea.recargo_linea, 5_000, 'recargo')
    ok &&= assert_eq(linea.monto_neto, 105_000, 'neto')
    ok ? (puts '  OK'; true) : false
  end

  def caso_recargo_monto_linea
    puts "\n[G3] Recargo $500 por línea"
    linea = calc_linea(
      cantidad: 3,
      precio_unitario: 1_000,
      recargo: 500,
      afecto: true
    )
    ok = true
    ok &&= assert_eq(linea.monto_bruto, 3_000, 'bruto')
    ok &&= assert_eq(linea.recargo_linea, 500, 'recargo monto')
    ok &&= assert_eq(linea.monto_neto, 3_500, 'neto')
    ok ? (puts '  OK'; true) : false
  end

  def caso_descuento_y_recargo_linea
    puts "\n[G4] Descuento 10% + recargo $200 en misma línea"
    linea = calc_linea(
      cantidad: 2,
      precio_unitario: 10_000,
      descuento_pct: 10,
      recargo: 200,
      afecto: true
    )
    ok = true
    ok &&= assert_eq(linea.descuento_linea, 2_000, 'descuento')
    ok &&= assert_eq(linea.recargo_linea, 200, 'recargo')
    ok &&= assert_eq(linea.monto_neto, 18_200, 'neto')
    ok ? (puts '  OK'; true) : false
  end

  def caso_xml_recargo_monto
    puts "\n[G5] GeneradorXml emite RecargoMonto"
    gen = Dte::GeneradorXml.new(
      emisor: emisor_fixture,
      receptor: receptor_fixture,
      documento: { tipo_dte: 33, fecha_emision: '2026-06-27', timestamp: '2026-06-27T12:00:00' },
      paginas: [{
        numero: 1,
        folio: 1,
        items: [{
          codigo: 'P001',
          glosa: 'Producto prueba',
          cantidad: 1,
          precio_unitario: 10_000,
          recargo: 500,
          recargo_pct: 0,
          descuento_pct: 0,
          descuento: 0,
          neto: 10_500
        }],
        totales: {
          neto_afecto: 10_500,
          neto_exento: 0,
          tasa_iva: 19,
          iva: 1_995,
          total: 12_495
        }
      }],
      rut_envia: '76123456-7',
      actecos: []
    )

    xml = gen.send(:construir_xml).to_xml
    doc = Nokogiri::XML(xml)
    recargo_monto = doc.at_xpath('//xmlns:RecargoMonto', 'xmlns' => Dte::GeneradorXml::NAMESPACE)&.text
    monto_item = doc.at_xpath('//xmlns:MontoItem', 'xmlns' => Dte::GeneradorXml::NAMESPACE)&.text

    ok = true
    ok &&= assert_eq(recargo_monto, '500', 'RecargoMonto en XML')
    ok &&= assert_eq(monto_item, '10500', 'MontoItem en XML')
    ok ? (puts '  OK'; true) : false
  end

  def emisor_fixture
    {
      rut: '76123456-7',
      razon_social: 'Empresa Test',
      giro: 'Servicios',
      direccion: 'Calle 1',
      telefono: '123',
      fecha_resolucion: '2014-08-22',
      numero_resolucion: '80'
    }
  end

  def receptor_fixture
    {
      rut: '12345678-9',
      razon_social: 'Cliente Test',
      giro: 'Comercio',
      direccion: 'Calle 2'
    }
  end
end

VerifyF1Linea.run!

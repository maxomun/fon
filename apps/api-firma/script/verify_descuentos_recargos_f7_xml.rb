#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase 7: serialización XML <DscRcgGlobal> (sin Rails).
# Uso: ruby script/verify_descuentos_recargos_f7_xml.rb

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

require File.join(ROOT, 'app/services/dte/generador_xml.rb')
require 'nokogiri'

unless ''.respond_to?(:present?)
  class Object
    def present?
      !nil? && !empty?
    end

    def blank?
      !present?
    end
  end

  class NilClass
    def present?
      false
    end

    def blank?
      true
    end
  end

  class FalseClass
    def present?
      false
    end

    def blank?
      true
    end
  end
end

module VerifyF7Xml
  module_function

  NS = { 'xmlns' => Dte::GeneradorXml::NAMESPACE }
  C = Dte::DescuentosRecargos::Constants

  def run!
    puts '=== Verificación F7: XML DscRcgGlobal ==='
    failures = 0
    failures += 1 unless caso_sin_globales_sin_nodo
    failures += 1 unless caso_4919151_4_xml
    failures += 1 unless caso_dual_afecto_exento_xml
    failures += 1 unless caso_recargo_porcentaje_xml
    failures += 1 unless caso_monto_fijo_no_facturable_xml

    if failures.zero?
      puts "\n✅ F7 XML: todos los casos pasaron (#{5} escenarios)"
      exit 0
    else
      puts "\n❌ F7 XML: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def xpath_text(doc, path)
    doc.at_xpath(path, NS)&.text
  end

  def xpath_all(doc, path)
    doc.xpath(path, NS)
  end

  def item_afecto(cantidad:, precio:, glosa: 'Item afecto')
    neto = cantidad * precio
    {
      codigo: 'A001',
      glosa: glosa,
      pagina: 1,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: neto,
      descuento_pct: 0,
      descuento: 0,
      recargo_pct: 0,
      recargo: 0,
      ambito_monto: C::APLICA_SOBRE_AFECTO,
      afecto: true,
      impuestos: [{ codigo: 'IVA', tasa: 19 }]
    }
  end

  def item_exento(cantidad:, precio:, glosa: 'Item exento')
    {
      codigo: 'E001',
      glosa: glosa,
      pagina: 1,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: cantidad * precio,
      descuento_pct: 0,
      descuento: 0,
      recargo_pct: 0,
      recargo: 0,
      ambito_monto: C::APLICA_SOBRE_EXENTO,
      afecto: false,
      impuestos: []
    }
  end

  def item_no_facturable(cantidad:, precio:, glosa: 'Item no facturable')
    {
      codigo: 'N001',
      glosa: glosa,
      pagina: 1,
      cantidad: cantidad,
      precio_unitario: precio,
      neto: cantidad * precio,
      descuento_pct: 0,
      descuento: 0,
      recargo_pct: 0,
      recargo: 0,
      ambito_monto: C::APLICA_SOBRE_NO_FACTURABLE,
      afecto: false,
      impuestos: []
    }
  end

  def pagina_desde_integrador(items, movimientos_raw = nil, folio: 1)
    resultado = Dte::DescuentosRecargos::IntegradorPagina.call(
      items_pagina: items,
      movimientos_globales_raw: movimientos_raw
    )
    raise "Integrador falló: #{resultado[:errors] || resultado[:error]}" unless resultado[:success]

    {
      numero: 1,
      folio: folio,
      items: items,
      totales: resultado[:totales],
      descuentos_recargos_globales: resultado[:descuentos_recargos_globales]
    }
  end

  def generar_xml(paginas)
    gen = Dte::GeneradorXml.new(
      emisor: emisor_fixture,
      receptor: receptor_fixture,
      documento: { tipo_dte: 33, fecha_emision: '2026-06-27', timestamp: '2026-06-27T12:00:00' },
      paginas: paginas,
      rut_envia: '76123456-7',
      actecos: []
    )
    gen.send(:construir_xml).to_xml
  end

  def caso_sin_globales_sin_nodo
    puts "\n[X1] Sin globales — no debe haber DscRcgGlobal"
    items = [item_afecto(cantidad: 1, precio: 10_000)]
    pagina = pagina_desde_integrador(items)
    doc = Nokogiri::XML(generar_xml([pagina]))
    nodos = xpath_all(doc, '//xmlns:DscRcgGlobal')
    ok = nodos.empty?
    ok ? (puts '  OK'; true) : (puts "  FAIL encontró #{nodos.size} nodo(s)"; false)
  end

  def caso_4919151_4_xml
    puts "\n[X2] Caso 4919151-4 — descuento global 30% afectos"
    items = [
      item_afecto(cantidad: 567, precio: 7_872, glosa: 'ITEM 1 AFECTO'),
      item_afecto(cantidad: 240, precio: 9_871, glosa: 'ITEM 2 AFECTO'),
      item_exento(cantidad: 2, precio: 6_863, glosa: 'ITEM 3 SERVICIO EXENTO')
    ]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 30,
      aplica_sobre: 'AFECTO'
    }]
    pagina = pagina_desde_integrador(items, movimientos)
    doc = Nokogiri::XML(generar_xml([pagina]))

    nodos = xpath_all(doc, '//xmlns:DscRcgGlobal')
    ok = true
    ok &&= assert_eq(nodos.size, 1, 'cantidad DscRcgGlobal')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:NroLinDR'), '1', 'NroLinDR')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoMov'), 'D', 'TpoMov')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoValor'), '%', 'TpoValor')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:ValorDR'), '30', 'ValorDR')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:IndExeDR'), nil, 'sin IndExeDR afecto')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:MntNeto'), '4782725', 'MntNeto')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:IVA'), '908717', 'IVA')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:MntTotal'), '5705168', 'MntTotal')
    ok ? (puts '  OK'; true) : false
  end

  def caso_dual_afecto_exento_xml
    puts "\n[X3] §8 — dos DscRcgGlobal (afecto + exento IndExeDR=1)"
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
    pagina = pagina_desde_integrador(items, movimientos)
    doc = Nokogiri::XML(generar_xml([pagina]))

    nodos = xpath_all(doc, '//xmlns:DscRcgGlobal')
    ok = true
    ok &&= assert_eq(nodos.size, 2, 'cantidad DscRcgGlobal')
    ok &&= assert_eq(nodos[0].at_xpath('xmlns:NroLinDR', NS)&.text, '1', 'nro 1')
    ok &&= assert_eq(nodos[0].at_xpath('xmlns:IndExeDR', NS)&.text, nil, 'sin IndExe en afecto')
    ok &&= assert_eq(nodos[1].at_xpath('xmlns:NroLinDR', NS)&.text, '2', 'nro 2')
    ok &&= assert_eq(nodos[1].at_xpath('xmlns:IndExeDR', NS)&.text, '1', 'IndExeDR exento')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:MntNeto'), '90000', 'MntNeto')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:MntExe'), '45000', 'MntExe')
    ok ? (puts '  OK'; true) : false
  end

  def caso_recargo_porcentaje_xml
    puts "\n[X4] Recargo 5% afecto — TpoMov R"
    items = [item_afecto(cantidad: 1, precio: 100_000)]
    movimientos = [{
      tipo_movimiento: 'R',
      glosa: 'Recargo comercial',
      tipo_valor: 'PORCENTAJE',
      valor: 5,
      aplica_sobre: 'AFECTO'
    }]
    pagina = pagina_desde_integrador(items, movimientos)
    doc = Nokogiri::XML(generar_xml([pagina]))

    ok = true
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoMov'), 'R', 'TpoMov recargo')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:ValorDR'), '5', 'ValorDR 5%')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:MntNeto'), '105000', 'MntNeto post-recargo')
    ok ? (puts '  OK'; true) : false
  end

  def caso_monto_fijo_no_facturable_xml
    puts "\n[X5] Descuento monto fijo no facturable — IndExeDR=2"
    items = [
      item_afecto(cantidad: 1, precio: 50_000),
      item_no_facturable(cantidad: 1, precio: 10_000)
    ]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'MONTO',
      valor: 2_000,
      aplica_sobre: 'NO_FACTURABLE'
    }]
    pagina = pagina_desde_integrador(items, movimientos)
    doc = Nokogiri::XML(generar_xml([pagina]))

    ok = true
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoValor'), '$', 'TpoValor monto')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:ValorDR'), '2000', 'ValorDR monto')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:IndExeDR'), '2', 'IndExeDR no facturable')
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
      rut: '66666666-6',
      razon_social: 'Cliente Test',
      giro: 'Comercio',
      direccion: 'Av. 2'
    }
  end
end

VerifyF7Xml.run!

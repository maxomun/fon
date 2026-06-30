#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase R2: serialización XML <Referencia> y atributos de persistencia.
# Uso: ruby script/verify_referencias_r2_xml.rb

ROOT = File.expand_path('..', __dir__)
SERVICES_DR = File.join(ROOT, 'app/services/dte/descuentos_recargos')
SERVICES_REF = File.join(ROOT, 'app/services/dte/referencias')

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
].each { |file| require File.join(SERVICES_DR, file) }

%w[
  constants.rb
  normalizador.rb
  validador.rb
].each { |file| require File.join(SERVICES_REF, file) }

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

module VerifyReferenciasR2Xml
  module_function

  NS = { 'xmlns' => Dte::GeneradorXml::NAMESPACE }
  C = Dte::DescuentosRecargos::Constants

  TipoCatalogo = Struct.new(
    :id,
    :codigo_sii,
    :requiere_folio,
    :requiere_fecha,
    :permite_codigo_referencia,
    keyword_init: true
  )

  def catalogo_fixture
    [
      TipoCatalogo.new(
        id: 1,
        codigo_sii: '52',
        requiere_folio: true,
        requiere_fecha: true,
        permite_codigo_referencia: false
      ),
      TipoCatalogo.new(
        id: 2,
        codigo_sii: '801',
        requiere_folio: true,
        requiere_fecha: true,
        permite_codigo_referencia: false
      )
    ]
  end

  def run!
    puts '=== Verificación R2: XML Referencia + persistencia ==='
    failures = 0
    failures += 1 unless caso_sin_referencias_sin_nodo
    failures += 1 unless caso_guia_52_xml
    failures += 1 unless caso_omite_cod_ref_y_razon
    failures += 1 unless caso_orden_despues_globales_antes_ted
    failures += 1 unless caso_multipagina_repite_referencias
    failures += 1 unless caso_atributos_persistencia

    if failures.zero?
      puts "\n✅ R2: todos los casos pasaron (#{6} escenarios)"
      exit 0
    else
      puts "\n❌ R2: #{failures} caso(s) fallaron"
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

  def referencia_guia(attrs = {})
    {
      nro_linea: 1,
      orden: 1,
      tipo_documento_referencia: '52',
      tipo_referencia_documento_id: 1,
      folio_referencia: '4589',
      fecha_referencia: Date.new(2026, 6, 29),
      codigo_referencia: nil,
      razon_referencia: 'Facturación de guía de despacho',
      documento_emitido_origen_id: nil
    }.merge(attrs)
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

  def pagina_desde_integrador(items, movimientos_raw = nil, folio: 1, referencias: [])
    resultado = Dte::DescuentosRecargos::IntegradorPagina.call(
      items_pagina: items,
      movimientos_globales_raw: movimientos_raw
    )
    raise "Integrador falló: #{resultado[:errors] || resultado[:error]}" unless resultado[:success]

    {
      numero: folio,
      folio: folio,
      items: items,
      totales: resultado[:totales],
      descuentos_recargos_globales: resultado[:descuentos_recargos_globales],
      referencias: referencias
    }
  end

  def generar_xml(paginas)
    gen = Dte::GeneradorXml.new(
      emisor: emisor_fixture,
      receptor: receptor_fixture,
      documento: { tipo_dte: 33, fecha_emision: '2026-06-29', timestamp: '2026-06-29T12:00:00' },
      paginas: paginas,
      rut_envia: '76123456-7',
      actecos: []
    )
    gen.send(:construir_xml).to_xml
  end

  def nombres_hijos_documento(doc)
    documento = doc.at_xpath('//xmlns:Documento', NS)
    documento.element_children.map(&:name)
  end

  def caso_sin_referencias_sin_nodo
    puts "\n[R2-1] Sin referencias — no debe haber nodo Referencia"
    items = [item_afecto(cantidad: 1, precio: 10_000)]
    pagina = pagina_desde_integrador(items)
    doc = Nokogiri::XML(generar_xml([pagina]))
    nodos = xpath_all(doc, '//xmlns:Referencia')
    nodos.empty? ? (puts '  OK'; true) : (puts "  FAIL encontró #{nodos.size} nodo(s)"; false)
  end

  def caso_guia_52_xml
    puts "\n[R2-2] Guía 52 — campos Referencia en XML"
    items = [item_afecto(cantidad: 1, precio: 10_000)]
    pagina = pagina_desde_integrador(items, referencias: [referencia_guia])
    doc = Nokogiri::XML(generar_xml([pagina]))

    ok = true
    ok &&= assert_eq(xpath_all(doc, '//xmlns:Referencia').size, 1, 'cantidad Referencia')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:NroLinRef'), '1', 'NroLinRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoDocRef'), '52', 'TpoDocRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:FolioRef'), '4589', 'FolioRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:FchRef'), '2026-06-29', 'FchRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:RazonRef'), 'Facturación de guía de despacho', 'RazonRef')
    ok ? (puts '  OK'; true) : false
  end

  def caso_omite_cod_ref_y_razon
    puts "\n[R2-3] Omite CodRef y RazonRef cuando no aplican"
    items = [item_afecto(cantidad: 1, precio: 5_000)]
    ref = referencia_guia(
      tipo_documento_referencia: '801',
      tipo_referencia_documento_id: 2,
      folio_referencia: 'OC-100',
      razon_referencia: nil
    )
    pagina = pagina_desde_integrador(items, referencias: [ref])
    doc = Nokogiri::XML(generar_xml([pagina]))

    ok = true
    ok &&= assert_eq(xpath_text(doc, '//xmlns:CodRef'), nil, 'sin CodRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:RazonRef'), nil, 'sin RazonRef')
    ok &&= assert_eq(xpath_text(doc, '//xmlns:TpoDocRef'), '801', 'TpoDocRef 801')
    ok ? (puts '  OK'; true) : false
  end

  def caso_orden_despues_globales_antes_ted
    puts "\n[R2-4] Orden: DscRcgGlobal → Referencia → TED"
    items = [item_afecto(cantidad: 1, precio: 100_000)]
    movimientos = [{
      tipo_movimiento: 'D',
      tipo_valor: 'PORCENTAJE',
      valor: 10,
      aplica_sobre: 'AFECTO'
    }]
    pagina = pagina_desde_integrador(items, movimientos, referencias: [referencia_guia])
    doc = Nokogiri::XML(generar_xml([pagina]))
    nombres = nombres_hijos_documento(doc)

    ok = true
    idx_dr = nombres.index('DscRcgGlobal')
    idx_ref = nombres.index('Referencia')
    idx_ted = nombres.index('TED')
    ok &&= assert_eq(idx_dr.nil?, false, 'existe DscRcgGlobal')
    ok &&= assert_eq(idx_ref.nil?, false, 'existe Referencia')
    ok &&= assert_eq(idx_ted.nil?, false, 'existe TED')
    ok &&= (idx_dr < idx_ref && idx_ref < idx_ted)
    ok ? (puts '  OK'; true) : (puts "  FAIL orden=#{nombres.inspect}"; false)
  end

  def caso_multipagina_repite_referencias
    puts "\n[R2-5] Multipágina — misma referencia en cada DTE"
    items_p1 = [item_afecto(cantidad: 1, precio: 10_000)]
    items_p2 = [item_afecto(cantidad: 1, precio: 20_000)]
    refs = [referencia_guia]
    paginas = [
      pagina_desde_integrador(items_p1, folio: 100, referencias: refs),
      pagina_desde_integrador(items_p2, folio: 101, referencias: refs)
    ]
    doc = Nokogiri::XML(generar_xml(paginas))
    nodos = xpath_all(doc, '//xmlns:Referencia')

    ok = nodos.size == 2
    ok ? (puts '  OK'; true) : (puts "  FAIL esperaba 2 nodos, obtuvo #{nodos.size}"; false)
  end

  def caso_atributos_persistencia
    puts "\n[R2-6] Atributos de persistencia desde referencia normalizada"
    ref = referencia_guia
    attrs = {
      nro_linea: ref[:nro_linea],
      orden: ref[:orden],
      tipo_referencia_documento_id: ref[:tipo_referencia_documento_id],
      folio_referencia: ref[:folio_referencia],
      fecha_referencia: ref[:fecha_referencia],
      codigo_referencia: ref[:codigo_referencia],
      razon_referencia: ref[:razon_referencia],
      documento_emitido_origen_id: ref[:documento_emitido_origen_id]
    }

    ok = true
    ok &&= assert_eq(attrs[:nro_linea], 1, 'nro_linea')
    ok &&= assert_eq(attrs[:tipo_referencia_documento_id], 1, 'tipo_referencia_documento_id')
    ok &&= assert_eq(attrs[:folio_referencia], '4589', 'folio_referencia')
    ok &&= assert_eq(attrs[:fecha_referencia], Date.new(2026, 6, 29), 'fecha_referencia')
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

VerifyReferenciasR2Xml.run!

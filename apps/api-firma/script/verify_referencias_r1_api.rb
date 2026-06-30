#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase R1: parser, validador y catálogo de referencias DTE.
# Uso local: ruby script/verify_referencias_r1_api.rb
# Uso Docker: docker compose exec -T facturaon-api ruby script/verify_referencias_r1_api.rb

ROOT = File.expand_path('..', __dir__)
SERVICES = File.join(ROOT, 'app/services/dte/referencias')

%w[
  constants.rb
  normalizador.rb
  validador.rb
].each { |file| require File.join(SERVICES, file) }

module VerifyReferenciasR1Api
  module_function

  TipoCatalogo = Struct.new(
    :id,
    :codigo_sii,
    :requiere_folio,
    :requiere_fecha,
    :permite_codigo_referencia,
    keyword_init: true
  )

  def catalogo_fixture
    {
      '52' => TipoCatalogo.new(
        id: 1,
        codigo_sii: '52',
        requiere_folio: true,
        requiere_fecha: true,
        permite_codigo_referencia: false
      ),
      '801' => TipoCatalogo.new(
        id: 2,
        codigo_sii: '801',
        requiere_folio: true,
        requiere_fecha: true,
        permite_codigo_referencia: false
      ),
      '56' => TipoCatalogo.new(
        id: 3,
        codigo_sii: '56',
        requiere_folio: true,
        requiere_fecha: true,
        permite_codigo_referencia: true
      )
    }.values
  end

  def run!
    puts '=== Verificación R1: contrato API referencias DTE ==='
    failures = 0
    failures += 1 unless caso_vacio_valido
    failures += 1 unless caso_parser_rechaza_no_array
    failures += 1 unless caso_parser_rechaza_campo_faltante
    failures += 1 unless caso_referencia_guia_52_valida
    failures += 1 unless caso_rechaza_tipo_inexistente
    failures += 1 unless caso_rechaza_folio_largo
    failures += 1 unless caso_rechaza_fecha_invalida
    failures += 1 unless caso_rechaza_cod_ref_en_801
    failures += 1 unless caso_nc_requiere_cod_ref
    failures += 1 unless caso_max_40_referencias
    failures += 1 unless caso_aliases_sii

    if failures.zero?
      puts "\n✅ R1 API: todos los casos pasaron (#{11} escenarios)"
      exit 0
    else
      puts "\n❌ R1 API: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_ok(result, label)
    return true if result[:success]

    puts "  FAIL #{label}: #{Array(result[:errors] || result[:error]).join('; ')}"
    false
  end

  def assert_fail(result, label, fragmento = nil)
    return true if !result[:success] && (fragmento.nil? || result[:errors].join(' ').include?(fragmento))

    puts "  FAIL #{label}: se esperaba error#{fragmento ? " con '#{fragmento}'" : ''}"
    false
  end

  def validar(raw, tipo_documento_emision: '33')
    Dte::Referencias::Validador.call(
      raw: raw,
      tipo_documento_emision: tipo_documento_emision,
      catalogo: catalogo_fixture
    )
  end

  def caso_vacio_valido
    puts '[R1-1] Sin referencias es válido'
    r = validar(nil)
    assert_ok(r, 'nil') && r[:referencias] == []
  end

  def caso_parser_rechaza_no_array
    puts '[R1-2] Rechaza referencias que no son arreglo'
    assert_fail(validar({}), 'objeto en lugar de arreglo', 'arreglo')
  end

  def caso_parser_rechaza_campo_faltante
    puts '[R1-3] Rechaza campo requerido faltante'
    raw = [{ tipo_documento_referencia: '52', folio_referencia: '1' }]
    assert_fail(validar(raw), 'fecha faltante', 'fecha_referencia')
  end

  def caso_referencia_guia_52_valida
    puts '[R1-4] Acepta guía 52 con folio y fecha'
    raw = [
      {
        tipo_documento_referencia: '52',
        folio_referencia: '4589',
        fecha_referencia: '2026-06-29',
        razon_referencia: 'Facturación de guía de despacho'
      }
    ]
    r = validar(raw)
    assert_ok(r, 'guía 52') &&
      r[:referencias].size == 1 &&
      r[:referencias].first[:nro_linea] == 1 &&
      r[:referencias].first[:tipo_referencia_documento_id] == 1 &&
      r[:referencias].first[:fecha_referencia] == Date.new(2026, 6, 29)
  end

  def caso_rechaza_tipo_inexistente
    puts '[R1-5] Rechaza TpoDocRef fuera de catálogo'
    raw = [
      {
        tipo_documento_referencia: '999',
        folio_referencia: '1',
        fecha_referencia: '2026-06-29'
      }
    ]
    assert_fail(validar(raw), 'tipo inexistente', 'catálogo activo')
  end

  def caso_rechaza_folio_largo
    puts '[R1-6] Rechaza folio > 18 caracteres'
    raw = [
      {
        tipo_documento_referencia: '52',
        folio_referencia: '1' * 19,
        fecha_referencia: '2026-06-29'
      }
    ]
    assert_fail(validar(raw), 'folio largo', '18 caracteres')
  end

  def caso_rechaza_fecha_invalida
    puts '[R1-7] Rechaza fecha con formato inválido'
    raw = [
      {
        tipo_documento_referencia: '52',
        folio_referencia: '1',
        fecha_referencia: '29-06-2026'
      }
    ]
    assert_fail(validar(raw), 'fecha inválida', 'YYYY-MM-DD')
  end

  def caso_rechaza_cod_ref_en_801
    puts '[R1-8] Rechaza CodRef en tipo que no lo permite (801)'
    raw = [
      {
        tipo_documento_referencia: '801',
        folio_referencia: 'OC-100',
        fecha_referencia: '2026-06-29',
        codigo_referencia: 1
      }
    ]
    assert_fail(validar(raw), 'cod_ref en 801', 'no aplica')
  end

  def caso_nc_requiere_cod_ref
    puts '[R1-9] NC exige codigo_referencia'
    raw = [
      {
        tipo_documento_referencia: '56',
        folio_referencia: '100',
        fecha_referencia: '2026-06-29'
      }
    ]
    assert_fail(validar(raw, tipo_documento_emision: '61'), 'NC sin cod_ref', 'codigo_referencia es obligatorio')
  end

  def caso_max_40_referencias
    puts '[R1-10] Rechaza más de 40 referencias'
    raw = Array.new(41) do |i|
      {
        tipo_documento_referencia: '52',
        folio_referencia: (i + 1).to_s,
        fecha_referencia: '2026-06-29'
      }
    end
    assert_fail(validar(raw), 'máximo 40', '40 referencias')
  end

  def caso_aliases_sii
    puts '[R1-11] Acepta alias SII (tpo_doc_ref, folio_ref, fch_ref)'
    raw = [
      {
        tpo_doc_ref: '801',
        folio_ref: 'OC-200',
        fch_ref: '2026-06-29',
        razon_ref: 'Orden de compra'
      }
    ]
    r = validar(raw)
    assert_ok(r, 'aliases') && r[:referencias].first[:tipo_documento_referencia] == '801'
  end
end

VerifyReferenciasR1Api.run!

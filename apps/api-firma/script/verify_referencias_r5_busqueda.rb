#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase R5: búsqueda y vínculo documento_emitido_origen_id.
# Uso: ruby script/verify_referencias_r5_busqueda.rb

ROOT = File.expand_path('..', __dir__)
SERVICES = File.join(ROOT, 'app/services/dte/referencias')

class DocumentoEmitido; end unless defined?(DocumentoEmitido)
class TipoReferenciaDocumento; end unless defined?(TipoReferenciaDocumento)

%w[
  constants.rb
  normalizador.rb
  documento_origen.rb
  validador.rb
].each { |file| require File.join(SERVICES, file) }

module VerifyReferenciasR5Busqueda
  module_function

  TipoCatalogo = Struct.new(
    :id,
    :codigo_sii,
    :requiere_folio,
    :requiere_fecha,
    :permite_codigo_referencia,
    :categoria,
    keyword_init: true
  )

  DocumentoStub = Struct.new(
    :id,
    :folio,
    :dte,
    :dte_envio_id,
    :empresa_id,
    :tipo_documento_codigo,
    :dte_envio,
    keyword_init: true
  ) do
    def dte?
      dte
    end
  end

  def catalogo_dte(codigo_sii)
    TipoCatalogo.new(
      id: 1,
      codigo_sii: codigo_sii,
      requiere_folio: true,
      requiere_fecha: true,
      permite_codigo_referencia: %w[56 61].include?(codigo_sii),
      categoria: 'DTE'
    )
  end

  CODIGOS_DTE_STUB = %w[33 34 39 41 46 52 56 61 110 111 112].freeze

  def run!
    puts '=== Verificación R5: vínculo documento origen ==='
    failures = 0
    failures += 1 unless caso_rechaza_origen_tipo_distinto
    failures += 1 unless caso_rechaza_origen_folio_distinto
    failures += 1 unless caso_acepta_origen_coherente

    if failures.zero?
      puts "\n✅ R5 vínculo origen: todos los casos pasaron (#{3} escenarios)"
      exit 0
    else
      puts "\n❌ R5 vínculo origen: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def stub_documento(folio: 100, tipo: '52', empresa_id: 1)
    DocumentoStub.new(
      id: 99,
      folio: folio,
      dte: true,
      dte_envio_id: 1,
      empresa_id: empresa_id,
      tipo_documento_codigo: tipo,
      dte_envio: Struct.new(:created_at, :xml_firmado).new(Time.utc(2026, 6, 29, 12), nil)
    )
  end

  def with_documento_stub(documento)
    relation = Object.new
    relation.define_singleton_method(:find_by) do |**attrs|
      attrs[:id] == documento.id && attrs[:empresa_id] == documento.empresa_id ? documento : nil
    end

    DocumentoEmitido.define_singleton_method(:includes) { |_args| relation }
    yield
  ensure
    DocumentoEmitido.singleton_class.remove_method(:includes) if DocumentoEmitido.singleton_methods.include?(:includes)
  end

  def with_tipo_referencia_stub
    catalogo_fn = method(:catalogo_dte)
    codigos = CODIGOS_DTE_STUB
    scope = Object.new
    scope.define_singleton_method(:find_by) do |codigo_sii:|
      codigos.include?(codigo_sii) ? catalogo_fn.call(codigo_sii) : nil
    end

    TipoReferenciaDocumento.define_singleton_method(:activos) { scope }
    yield
  ensure
    if TipoReferenciaDocumento.singleton_methods.include?(:activos)
      TipoReferenciaDocumento.singleton_class.remove_method(:activos)
    end
  end

  def validar_origen(referencia, empresa_id: 1)
    with_tipo_referencia_stub do
      with_documento_stub(stub_documento) do
        Dte::Referencias::DocumentoOrigen.validar_vinculo(
          referencia: referencia,
          empresa_id: empresa_id,
          prefijo: 'referencias[0]'
        )
      end
    end
  end

  def caso_rechaza_origen_tipo_distinto
    puts "\n[R5-1] Rechaza origen si TpoDocRef no coincide"
    referencia = {
      tipo_documento_referencia: '33',
      folio_referencia: '100',
      fecha_referencia: '2026-06-29',
      documento_emitido_origen_id: 99
    }
    errores = validar_origen(referencia)
    ok = errores.any? { |e| e.include?('tipo_documento_referencia') }
    ok ? (puts '  OK'; true) : (puts "  FAIL #{errores.inspect}"; false)
  end

  def caso_rechaza_origen_folio_distinto
    puts "\n[R5-2] Rechaza origen si folio no coincide"
    referencia = {
      tipo_documento_referencia: '52',
      folio_referencia: '999',
      fecha_referencia: '2026-06-29',
      documento_emitido_origen_id: 99
    }
    errores = validar_origen(referencia)
    ok = errores.any? { |e| e.include?('folio_referencia') }
    ok ? (puts '  OK'; true) : (puts "  FAIL #{errores.inspect}"; false)
  end

  def caso_acepta_origen_coherente
    puts "\n[R5-3] Acepta origen coherente con folio y tipo"
    referencia = {
      tipo_documento_referencia: '52',
      folio_referencia: '100',
      fecha_referencia: '2026-06-29',
      documento_emitido_origen_id: 99
    }
    errores = validar_origen(referencia)
    errores.empty? ? (puts '  OK'; true) : (puts "  FAIL #{errores.inspect}"; false)
  end
end

VerifyReferenciasR5Busqueda.run!

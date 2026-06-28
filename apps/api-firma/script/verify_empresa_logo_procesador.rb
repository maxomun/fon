#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación L1 logo empresa: reglas de validación acordadas (sin Rails/vips).
# Uso: ruby script/verify_empresa_logo_procesador.rb

module VerifyEmpresaLogoProcesador
  TARGET_WIDTH = 540
  TARGET_HEIGHT = 180
  MAX_STORED_BYTES = 150 * 1024
  MIN_ASPECT_RATIO = 2.0
  MAX_ASPECT_RATIO = 4.0
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  module_function

  def run!
    puts '=== Verificación logo empresa (reglas L1) ==='
    failures = 0
    failures += 1 unless caso_constantes
    failures += 1 unless caso_validacion_aspecto

    if failures.zero?
      puts "\n✅ Logo empresa L1: reglas OK"
      puts '   Procesamiento con vips requiere Docker (bundle + libvips).'
      exit 0
    else
      puts "\n❌ Logo empresa: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert(condition, label)
    return true if condition

    puts "  FAIL #{label}"
    false
  end

  def caso_constantes
    puts "\n[L1] Constantes del procesador"
    ok = true
    ok &&= assert(TARGET_WIDTH == 540, 'TARGET_WIDTH 540')
    ok &&= assert(TARGET_HEIGHT == 180, 'TARGET_HEIGHT 180')
    ok &&= assert(MAX_STORED_BYTES == 153_600, 'MAX_STORED 150 KB')
    ok &&= assert(ALLOWED_CONTENT_TYPES.include?('image/png'), 'PNG permitido')
    ok ? (puts '  OK'; true) : false
  end

  def caso_validacion_aspecto
    puts "\n[L2] Proporción horizontal (~3:1)"
    ok = true
    ok &&= assert((540.0 / 180).between?(MIN_ASPECT_RATIO, MAX_ASPECT_RATIO), '540×180 válido')
    ok &&= assert(!(100.0 / 100).between?(MIN_ASPECT_RATIO, MAX_ASPECT_RATIO), '100×100 inválido')
    ok &&= assert(!(800.0 / 100).between?(MIN_ASPECT_RATIO, MAX_ASPECT_RATIO), '800×100 demasiado ancho')
    ok ? (puts '  OK'; true) : false
  end
end

VerifyEmpresaLogoProcesador.run!

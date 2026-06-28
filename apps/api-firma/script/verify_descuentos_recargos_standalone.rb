#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación sin Rails (no requiere bundle si Ruby está disponible).
# Uso: ruby script/verify_descuentos_recargos_standalone.rb

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
  calculador_documento.rb
].each { |file| require File.join(SERVICES, file) }

load File.join(ROOT, 'script/verify_descuentos_recargos_calculador.rb')

#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación PDF-3: estructura HTML/CSS para desborde multipágina.
# Uso: ruby script/verify_pdf_dte_multipagina.rb

ROOT = File.expand_path('..', __dir__)

def cargar_rails!
  require File.join(ROOT, 'config/environment')
rescue LoadError
  nil
end

module VerifyPdfMultipagina
  module_function

  MARCADORES_CSS = %w[
    encabezado-fijo
    documento-cuerpo
    detalle-box
    cierre-documento
    table-header-group
    page-break-inside: avoid
  ].freeze

  def run!
    puts '=== Verificación PDF-3 (multipágina / desborde) ==='
    failures = 0
    failures += 1 unless caso_estructura_html

    if failures.zero?
      puts "\n✅ PDF-3 multipágina: estructura OK"
      exit 0
    else
      puts "\n❌ PDF-3 multipágina: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def presentacion_fixture(lineas: 35)
    lineas_array = lineas.times.map do |i|
      {
        codigo: format('P%03d', i + 1),
        descripcion: "Ítem de prueba #{i + 1} con descripción extendida para forzar salto de línea en el PDF tributario",
        cantidad: 1.0,
        unidad: 'UN',
        precio_unitario: 10_000.0,
        descuento_pct: 0.0,
        recargo: 0,
        total: 10_000
      }
    end

    {
      tipo_dte: 33,
      tipo_dte_nombre: 'FACTURA ELECTRÓNICA',
      folio: 99,
      fecha_emision: '2026-06-28',
      sucursal: '',
      emisor: {
        razon_social: 'Empresa Demo SpA',
        rut: '12.345.678-9',
        giro: 'Servicios',
        direccion: 'Calle 123'
      },
      receptor: {
        razon_social: 'Cliente Largo Nombre Comercial SA',
        rut: '9.876.543-2',
        giro: 'Comercio',
        direccion: 'Av. Principal 456'
      },
      lineas: lineas_array,
      globales: [],
      referencias: [],
      totales: {
        neto_afecto: lineas * 10_000,
        neto_exento: 0,
        iva: (lineas * 10_000 * 0.19).to_i,
        total: (lineas * 10_000 * 1.19).to_i
      },
      ted_placeholder: true,
      ted_imagen_data_uri: nil,
      resolucion_timbre: 'Resolución Ex. SII N° 99 de 2014'
    }
  end

  def render_html(presentacion)
    if defined?(ActionController::Base)
      ActionController::Base.render(
        template: 'dte/pdf/documento',
        layout: false,
        locals: { presentacion: presentacion }
      )
    else
      cargar_rails!
      ActionController::Base.render(
        template: 'dte/pdf/documento',
        layout: false,
        locals: { presentacion: presentacion }
      )
    end
  end

  def caso_estructura_html
    puts "\n[M1] Plantilla multipágina (35 líneas)"
    html = render_html(presentacion_fixture(lineas: 35))

    unless html.bytesize > 5000
      puts "  FAIL: HTML demasiado corto (#{html.bytesize} bytes)"
      return false
    end

    faltantes = MARCADORES_CSS.reject { |m| html.include?(m) }
    if faltantes.any?
      puts "  FAIL: faltan marcadores CSS/HTML: #{faltantes.join(', ')}"
      return false
    end

    unless html.scan('<tr>').size >= 35
      puts '  FAIL: no se renderizaron todas las líneas de detalle'
      return false
    end

    unless html.include?('cierre-documento') && html.index('cierre-documento') > html.index('detalle-box')
      puts '  FAIL: el bloque de cierre debe ir después del detalle'
      return false
    end

    puts "  OK (#{html.bytesize} bytes, #{html.scan('<tr>').size} filas)"
    true
  rescue StandardError => e
    puts "  FAIL: #{e.class} — #{e.message}"
    false
  end
end

VerifyPdfMultipagina.run!

#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación Fase R4: referencias en presentador PDF y HTML.
# Uso: ruby script/verify_referencias_r4_pdf.rb

ROOT = File.expand_path('..', __dir__)

def cargar_rails!
  require File.join(ROOT, 'config/environment')
end

module VerifyReferenciasR4Pdf
  module_function

  def run!
    puts '=== Verificación R4: referencias en PDF/HTML ==='
    failures = 0
    failures += 1 unless caso_html_con_referencias
    failures += 1 unless caso_html_sin_referencias

    if failures.zero?
      puts "\n✅ R4 PDF/detalle: todos los casos pasaron (#{2} escenarios)"
      exit 0
    else
      puts "\n❌ R4 PDF/detalle: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def presentacion_base
    {
      tipo_dte: 33,
      tipo_dte_nombre: 'FACTURA ELECTRÓNICA',
      folio: 100,
      fecha_emision: '2026-06-29',
      sucursal: '',
      emisor: {
        razon_social: 'Empresa Demo SpA',
        rut: '12.345.678-9',
        giro: 'Servicios',
        direccion: 'Calle 123',
        comuna: '',
        ciudad: ''
      },
      receptor: {
        razon_social: 'Cliente Demo',
        rut: '9.876.543-2',
        giro: 'Comercio',
        direccion: 'Av. Principal 456',
        comuna: '',
        ciudad: ''
      },
      lineas: [
        {
          codigo: 'A001',
          descripcion: 'Producto demo',
          cantidad: 1.0,
          unidad: 'UN',
          precio_unitario: 10_000.0,
          descuento_pct: 0.0,
          recargo: 0,
          total: 10_000
        }
      ],
      globales: [],
      totales: {
        neto_afecto: 10_000,
        neto_exento: 0,
        iva: 1_900,
        total: 11_900
      },
      ted_placeholder: true,
      ted_imagen_data_uri: nil,
      logo_data_uri: nil,
      resolucion_timbre: 'Resolución Ex. SII N° 99 de 2014'
    }
  end

  def render_html(presentacion)
    cargar_rails!
    ActionController::Base.render(
      template: 'dte/pdf/documento',
      layout: false,
      locals: { presentacion: presentacion }
    )
  end

  def caso_html_con_referencias
    puts "\n[R4-1] HTML incluye tabla REFERENCIAS con datos"
    presentacion = presentacion_base.merge(
      referencias: [
        {
          tipo: '52 — Guía de Despacho Electrónica',
          folio: '4589',
          fecha: '29-06-2026',
          razon: 'Facturación de guía de despacho'
        }
      ]
    )

    html = render_html(presentacion)
    ok = html.include?('REFERENCIAS') &&
         html.include?('4589') &&
         html.include?('Facturación de guía de despacho')
    ok ? (puts '  OK'; true) : (puts '  FAIL HTML sin datos esperados'; false)
  rescue StandardError => e
    puts "  FAIL #{e.message}"
    false
  end

  def caso_html_sin_referencias
    puts "\n[R4-2] Sin referencias — no renderiza sección REFERENCIAS"
    presentacion = presentacion_base.merge(referencias: [])
    html = render_html(presentacion)
    ok = !html.include?('>REFERENCIAS<')
    ok ? (puts '  OK'; true) : (puts '  FAIL sección REFERENCIAS presente sin datos'; false)
  rescue StandardError => e
    puts "  FAIL #{e.message}"
    false
  end
end

VerifyReferenciasR4Pdf.run!

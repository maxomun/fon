#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación PDF-0/PDF-1: formateador, lector XML y presentador (sin Grover).
# Uso: ruby script/verify_pdf_dte_presentador.rb

ROOT = File.expand_path('..', __dir__)

require File.join(ROOT, 'app/services/dte/generador_xml.rb')
require File.join(ROOT, 'app/services/dte/pdf/formateador.rb')
require File.join(ROOT, 'app/services/dte/pdf/lector_totales_xml.rb')

module VerifyPdfPresentador
  module_function

  def run!
    puts '=== Verificación PDF DTE (presentador / lectura XML) ==='
    failures = 0
    failures += 1 unless caso_formateador_moneda
    failures += 1 unless caso_lector_totales_xml

    if failures.zero?
      puts "\n✅ PDF presentador: casos standalone OK"
      puts '   Generación PDF completa requiere Rails + Grover + Chromium (Docker).'
      exit 0
    else
      puts "\n❌ PDF presentador: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def assert_eq(actual, expected, label)
    return true if actual == expected

    puts "  FAIL #{label}: esperado #{expected.inspect}, obtuvo #{actual.inspect}"
    false
  end

  def caso_formateador_moneda
    puts "\n[P1] Formateador moneda CLP"
    ok = true
    ok &&= assert_eq(Dte::Pdf::Formateador.moneda(1_234_567), '$1.234.567', 'miles')
    ok &&= assert_eq(Dte::Pdf::Formateador.moneda(0), '$0', 'cero')
    ok ? (puts '  OK'; true) : false
  end

  def xml_fixture_4919151_4
    <<~XML
      <?xml version="1.0" encoding="ISO-8859-1"?>
      <EnvioDTE xmlns="http://www.sii.cl/SiiDte" version="1.0">
        <SetDTE ID="SetDoc">
          <DTE version="1.0">
            <Documento ID="F0000000001T33">
              <Encabezado>
                <IdDoc>
                  <TipoDTE>33</TipoDTE>
                  <Folio>1</Folio>
                  <FchEmis>2026-06-28</FchEmis>
                </IdDoc>
                <Totales>
                  <MntNeto>4782725</MntNeto>
                  <MntExe>13726</MntExe>
                  <TasaIVA>19</TasaIVA>
                  <IVA>908717</IVA>
                  <MntTotal>5705168</MntTotal>
                </Totales>
              </Encabezado>
            </Documento>
          </DTE>
        </SetDTE>
      </EnvioDTE>
    XML
  end

  def caso_lector_totales_xml
    puts "\n[P2] Lector totales desde XML por folio"
    totales = Dte::Pdf::LectorTotalesXml.call(xml_string: xml_fixture_4919151_4, folio: 1)
    return (puts '  FAIL sin totales'; false) unless totales

    ok = true
    ok &&= assert_eq(totales[:neto_afecto], 4_782_725, 'neto afecto')
    ok &&= assert_eq(totales[:iva], 908_717, 'iva')
    ok &&= assert_eq(totales[:total], 5_705_168, 'total')
    ok &&= assert_eq(totales[:fecha_emision], '2026-06-28', 'fecha')
    ok ? (puts '  OK'; true) : false
  end
end

VerifyPdfPresentador.run!

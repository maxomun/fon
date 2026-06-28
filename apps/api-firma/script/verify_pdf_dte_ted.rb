#!/usr/bin/env ruby
# frozen_string_literal: true

# Verificación PDF-2: extracción TED, serialización y generación PDF417.
# Uso: ruby script/verify_pdf_dte_ted.rb

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(ROOT) unless $LOAD_PATH.include?(ROOT)

require File.join(ROOT, 'app/services/dte/generador_xml.rb')
require File.join(ROOT, 'app/services/dte/pdf/lector_ted_xml.rb')
require File.join(ROOT, 'app/services/dte/pdf/serializador_ted.rb')
require File.join(ROOT, 'app/services/dte/pdf/generador_pdf417.rb')

module VerifyPdfTed
  module_function

  def run!
    puts '=== Verificación PDF-2 (TED / PDF417) ==='
    failures = 0
    failures += 1 unless caso_serializacion_ted
    failures += 1 unless caso_generacion_png

    if failures.zero?
      puts "\n✅ PDF-2 TED: casos OK"
      exit 0
    else
      puts "\n❌ PDF-2 TED: #{failures} caso(s) fallaron"
      exit 1
    end
  end

  def xml_fixture_con_ted
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
              </Encabezado>
              <TED version="1.0">
                <DD>
                  <RE>12023063-8</RE>
                  <TD>33</TD>
                  <F>1</F>
                  <FE>2026-06-28</FE>
                  <RR>1-9</RR>
                  <RSR>RZ Prueba</RSR>
                  <MNT>1190</MNT>
                  <IT1>Producto prueba</IT1>
                  <TSTED>2026-06-28T12:00:00</TSTED>
                </DD>
                <FRMT algoritmo="SHA1withRSA">dGVzdGZpcm1h</FRMT>
              </TED>
            </Documento>
          </DTE>
        </SetDTE>
      </EnvioDTE>
    XML
  end

  def caso_serializacion_ted
    puts "\n[T1] LectorTedXml + SerializadorTed"
    ted = Dte::Pdf::LectorTedXml.call(xml_string: xml_fixture_con_ted, folio: 1)
    unless ted
      puts '  FAIL: no se encontró TED'
      return false
    end

    serializado = Dte::Pdf::SerializadorTed.call(ted_node: ted)
    unless serializado&.include?('<TED') && serializado.include?('<FRMT')
      puts "  FAIL: serialización inválida: #{serializado.inspect}"
      return false
    end

    if serializado.match?(/>\s+</)
      puts '  FAIL: quedaron espacios entre tags'
      return false
    end

    puts "  OK (#{serializado.bytesize} bytes, ISO-8859-1)"
    true
  end

  def caso_generacion_png
    puts "\n[T2] GeneradorPdf417 (bwip-js)"
    ted = Dte::Pdf::LectorTedXml.call(xml_string: xml_fixture_con_ted, folio: 1)
    serializado = Dte::Pdf::SerializadorTed.call(ted_node: ted)
    png = Dte::Pdf::GeneradorPdf417.call(ted_string: serializado)

    unless png && png.bytesize > 500 && png[0, 8].bytes == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
      puts "  FAIL: PNG inválido (#{png&.bytesize || 0} bytes)"
      return false
    end

    puts "  OK (#{png.bytesize} bytes PNG)"
    true
  end
end

VerifyPdfTed.run!

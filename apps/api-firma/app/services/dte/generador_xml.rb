# frozen_string_literal: true

require 'cgi'

module Dte
  # Construye el XML de envío al SII (EnvioDTE) a partir de la estructura preparada
  # por el controller. Cada página del DTE se convierte en un nodo <DTE> independiente
  # con su propio folio, detalle de ítems y TED (timbre electrónico, aún sin firmar).
  #
  # El XML resultante NO está firmado: el CAF y las firmas RSA se insertan después
  # en Dte::Firmador.
  #
  # Ejemplo de uso:
  #   xml = Dte::GeneradorXml.call(
  #     emisor: { rut: '...', razon_social: '...', ... },
  #     receptor: { rut: '...', razon_social: '...', ... },
  #     documento: { tipo_dte: 33, fecha_emision: '2026-02-01', ... },
  #     paginas: [{ numero: 1, folio: 123, items: [...], totales: {...} }],
  #     rut_envia: '12345678-9'
  #   )
  #
  class GeneradorXml
    # Constantes del esquema XML exigido por el SII para el sobre de envío
    NAMESPACE = 'http://www.sii.cl/SiiDte'
    SCHEMA_LOCATION = 'http://www.sii.cl/SiiDte EnvioDTE_v10.xsd'
    VERSION = '1.0'

    attr_reader :emisor, :receptor, :documento, :paginas, :rut_envia, :actecos

    def initialize(emisor:, receptor:, documento:, paginas:, rut_envia:, actecos: [])
      @emisor = emisor
      @receptor = receptor
      @documento = documento
      @paginas = paginas
      @rut_envia = rut_envia
      @actecos = actecos
    end

    def self.call(**args)
      new(**args).call
    end

    # Serializa la estructura a XML y lo persiste en tmp/ para uso del firmador.
    #
    # @return [Hash] {
    #   exitoso: Boolean,
    #   xml: String con el XML sin firmar (encoding ISO-8859-1),
    #   archivo: ruta del archivo temporal,
    #   total_documentos: cantidad de nodos <DTE> generados (uno por página)
    # }
    def call
      builder = construir_xml
      # El SII exige ISO-8859-1 para documentos tributarios electrónicos
      xml_string = builder.to_xml(indent: 2, encoding: 'ISO-8859-1')

      # Archivo temporal consumido por Dte::Firmador y luego eliminado por el controller
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      archivo = Rails.root.join('tmp', "dte_#{documento[:tipo_dte]}_#{timestamp}.xml")

      File.write(archivo, xml_string, encoding: 'ISO-8859-1')

      {
        exitoso: true,
        xml: xml_string,
        archivo: archivo.to_s,
        total_documentos: paginas.count
      }
    rescue StandardError => e
      Rails.logger.error("Error generando XML: #{e.message}")
      {
        exitoso: false,
        error: e.message,
        xml: nil,
        archivo: nil
      }
    end

    private

    # Estructura raíz del sobre de envío:
    #   EnvioDTE → SetDTE → Caratula + N × DTE
    def construir_xml
      Nokogiri::XML::Builder.new(encoding: 'ISO-8859-1') do |xml|
        xml.EnvioDTE(
          'xmlns' => NAMESPACE,
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xsi:schemaLocation' => SCHEMA_LOCATION,
          'version' => VERSION
        ) do
          xml.SetDTE('ID' => 'SetDoc') do
            construir_caratula(xml)
            construir_documentos(xml)
          end
        end
      end
    end

    # Metadatos del lote: identifica emisor, enviador, receptor y cantidad de DTEs
    def construir_caratula(xml)
      xml.Caratula('version' => '1.0') do
        xml.RutEmisor limpiar_rut(emisor[:rut])
        xml.RutEnvia limpiar_rut(rut_envia)
        xml.RutReceptor limpiar_rut(receptor[:rut])
        xml.FchResol formatear_fecha(emisor[:fecha_resolucion])
        xml.NroResol emisor[:numero_resolucion].to_s
        xml.TmstFirmaEnv documento[:timestamp]
        xml.SubTotDTE do
          xml.TpoDTE documento[:tipo_dte]
          xml.NroDTE paginas.count
        end
      end
    end

    # Un documento tributario por página (paginación por espacio en el PDF)
    def construir_documentos(xml)
      paginas.each do |pagina|
        xml.DTE('version' => '1.0') do
          construir_documento(xml, pagina)
        end
      end
    end

    # Nodo <Documento> con ID único (ej: F0000000123T33) usado luego como referencia de firma
    def construir_documento(xml, pagina)
      id_documento = generar_id_documento(pagina[:folio])
      items = pagina[:items] || []
      totales = pagina[:totales] || {}

      xml.Documento('ID' => id_documento) do
        construir_encabezado(xml, pagina[:folio], totales)
        construir_detalles(xml, items)
        construir_descuentos_recargos_globales(xml, pagina)
        construir_referencias(xml, pagina)
        # TED incluye datos resumidos del DTE; la firma del timbre se agrega en Dte::Firmador
        construir_timbre_electronico(xml, pagina[:folio], totales, items)
        xml.TmstFirma documento[:timestamp]
      end
    end

    def construir_encabezado(xml, folio, totales)
      xml.Encabezado do
        construir_id_doc(xml, folio)
        construir_emisor(xml)
        construir_receptor(xml)
        construir_totales(xml, totales)
      end
    end

    def construir_id_doc(xml, folio)
      xml.IdDoc do
        xml.TipoDTE documento[:tipo_dte]
        xml.Folio folio
        xml.FchEmis documento[:fecha_emision]
      end
    end

    def construir_emisor(xml)
      xml.Emisor do
        xml.RUTEmisor limpiar_rut(emisor[:rut])
        xml.RznSoc escape_xml(emisor[:razon_social])
        xml.GiroEmis escape_xml(truncar(emisor[:giro], 80))
        xml.Telefono emisor[:telefono] if emisor[:telefono].present?
        xml.CorreoEmisor emisor[:email] if emisor[:email].present?

        # Actividades económicas
        actecos.each do |acteco|
          xml.Acteco acteco[:codigo]
        end

        xml.DirOrigen escape_xml(truncar(emisor[:direccion], 70))
        xml.CmnaOrigen escape_xml(emisor[:comuna]) if emisor[:comuna].present?
        xml.CiudadOrigen escape_xml(emisor[:ciudad]) if emisor[:ciudad].present?
      end
    end

    def construir_receptor(xml)
      xml.Receptor do
        xml.RUTRecep limpiar_rut(receptor[:rut])
        xml.RznSocRecep escape_xml(truncar(receptor[:razon_social], 100))
        xml.GiroRecep escape_xml(truncar(receptor[:giro], 40))
        xml.DirRecep escape_xml(truncar(receptor[:direccion], 70))
        xml.CmnaRecep escape_xml(receptor[:comuna]) if receptor[:comuna].present?
        xml.CiudadRecep escape_xml(receptor[:ciudad]) if receptor[:ciudad].present?
      end
    end

    # Solo se incluyen nodos con valor > 0 (requisito del esquema SII)
    def construir_totales(xml, totales)
      xml.Totales do
        xml.MntNeto totales[:neto_afecto].to_i if totales[:neto_afecto].to_i > 0
        xml.MntExe totales[:neto_exento].to_i if totales[:neto_exento].to_i > 0
        xml.TasaIVA totales[:tasa_iva] if totales[:neto_afecto].to_i > 0
        xml.IVA totales[:iva].to_i if totales[:iva].to_i > 0
        xml.MntTotal totales[:total].to_i
      end
    end

    def construir_detalles(xml, items)
      items.each_with_index do |item, index|
        xml.Detalle do
          xml.NroLinDet index + 1
          construir_codigo_item(xml, item)
          xml.NmbItem escape_xml(truncar(item[:glosa], 80))
          xml.DscItem escape_xml(truncar(item[:glosa], 1000)) if item[:glosa].length > 80
          xml.QtyItem item[:cantidad]
          xml.PrcItem item[:precio_unitario].to_i
          xml.DescuentoPct item[:descuento_pct] if item[:descuento_pct].to_f > 0
          xml.DescuentoMonto item[:descuento].to_i if item[:descuento].to_i > 0
          xml.RecargoPct item[:recargo_pct] if item[:recargo_pct].to_f > 0
          xml.RecargoMonto item[:recargo].to_i if item[:recargo].to_i > 0
          ind_exe = ind_exe_detalle_item(item)
          xml.IndExe ind_exe if ind_exe
          xml.MontoItem item[:neto].to_i
        end
      end
    end

    # Descuentos/recargos globales (SII <DscRcgGlobal>) — después de Detalle, antes de TED.
    def construir_descuentos_recargos_globales(xml, pagina)
      movimientos = Array(pagina[:descuentos_recargos_globales])
      return if movimientos.empty?

      movimientos.each do |movimiento_raw|
        movimiento = normalizar_movimiento_global(movimiento_raw)
        xml.DscRcgGlobal do
          xml.NroLinDR movimiento.nro_linea
          xml.TpoMov movimiento.tipo_movimiento
          xml.GlosaDR escape_xml(truncar(movimiento.glosa_para_xml, 45))
          xml.TpoValor movimiento.xml_tpo_valor
          xml.ValorDR formatear_valor_dr(movimiento)
          ind_exe = movimiento.xml_ind_exe_dr
          xml.IndExeDR ind_exe if ind_exe
        end
      end
    end

    def normalizar_movimiento_global(raw)
      return raw if raw.is_a?(Dte::DescuentosRecargos::MovimientoGlobal)

      Dte::DescuentosRecargos::MovimientoGlobal.from_hash(raw)
    end

    def formatear_valor_dr(movimiento)
      valor = movimiento.valor
      return valor.to_i unless movimiento.porcentaje?
      return valor.to_i if valor == valor.to_i

      valor
    end

    # Referencias SII (<Referencia>) — después de DscRcgGlobal, antes de TED.
    def construir_referencias(xml, pagina)
      referencias = Array(pagina[:referencias])
      return if referencias.empty?

      referencias.each do |referencia_raw|
        referencia = normalizar_referencia(referencia_raw)
        xml.Referencia do
          xml.NroLinRef referencia[:nro_linea]
          xml.TpoDocRef referencia[:tipo_documento_referencia]
          xml.FolioRef escape_xml(truncar(referencia[:folio_referencia], 18))
          xml.FchRef formatear_fecha(referencia[:fecha_referencia])
          codigo = referencia[:codigo_referencia]
          xml.CodRef codigo if codigo
          razon = referencia[:razon_referencia].to_s.strip
          xml.RazonRef escape_xml(truncar(razon, 90)) unless razon.empty?
        end
      end
    end

    def normalizar_referencia(raw)
      return raw.transform_keys(&:to_sym) if raw.is_a?(Hash)

      raw
    end

    def construir_codigo_item(xml, item)
      xml.CdgItem do
        xml.TpoCodigo 'INT1'
        xml.VlrCodigo item[:codigo]
      end
    end

    def ind_exe_detalle_item(item)
      Dte::DescuentosRecargos::ClasificacionMonto.desde_item(item).ind_exe_detalle
    end

    # TED (Timbre Electrónico DTE): bloque <DD> con datos mínimos para validación SII.
    # El nodo <CAF> y el contenido de <FRMT> se completan en la fase de firma.
    def construir_timbre_electronico(xml, folio, totales, items)
      primer_item = items.first || {}

      xml.TED('version' => '1.0') do
        xml.DD do
          # RE=emisor, TD=tipo, F=folio, FE=fecha, RR=receptor, RSR=razón social receptor,
          # MNT=total, IT1=primer ítem, TSTED=timestamp del timbre
          xml.RE limpiar_rut(emisor[:rut])
          xml.TD documento[:tipo_dte]
          xml.F folio
          xml.FE documento[:fecha_emision]
          xml.RR limpiar_rut(receptor[:rut])
          xml.RSR escape_xml(truncar(receptor[:razon_social], 40))
          xml.MNT totales[:total].to_i
          xml.IT1 escape_xml(truncar(primer_item[:glosa] || '', 40))
          xml.TSTED documento[:timestamp]
        end
        # CAF se insertará aquí en la fase de firma
        xml.FRMT('algoritmo' => 'SHA1withRSA')
      end
    end

    def generar_id_documento(folio)
      # Formato SII: F + folio (10 dígitos) + T + tipo DTE
      folio_str = folio.to_s.rjust(10, '0')
      "F#{folio_str}T#{documento[:tipo_dte]}"
    end

    def formatear_fecha(fecha)
      return fecha if fecha.is_a?(String)
      return fecha.strftime('%Y-%m-%d') if fecha.respond_to?(:strftime)

      fecha.to_s
    end

    def escape_xml(texto)
      return '' if texto.nil?

      CGI.escapeHTML(texto.to_s)
    end

    def truncar(texto, longitud)
      return '' if texto.nil?

      texto.to_s[0, longitud]
    end

    def limpiar_rut(rut)
      return '' if rut.nil?

      # Elimina puntos y espacios, mantiene el guión del dígito verificador
      rut.to_s.gsub(/[.\s]/, '')
    end
  end
end

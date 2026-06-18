# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'nokogiri'

module Dte
  class Firmador
    XMLNS_SII = 'http://www.sii.cl/SiiDte'
    XMLNS_DS = 'http://www.w3.org/2000/09/xmldsig#'

    def self.call(**params)
      new(**params).call
    end

    def initialize(xml_string:, empresa_id:, paginas:, certificado: nil)
      @xml_string = xml_string
      @empresa_id = empresa_id
      @paginas = paginas
      @certificado = certificado
      @xml = nil
    end

    def call
      Rails.logger.info "=== FIRMADOR: Iniciando firma de DTE ==="
      
      # Parsear XML
      @xml = Nokogiri::XML(@xml_string)
      @xml.encoding = 'ISO-8859-1'
      
      certificado = certificado_para_firma
      unless certificado
        return { success: false, error: @error_resolucion_certificado || 'No hay certificado vigente para la empresa' }
      end
      
      Rails.logger.info "=== FIRMADOR: Certificado obtenido (firma vía xmlsec1) ==="
      
      # 1. Insertar CAF y firmar cada documento (TED + Signature)
      @paginas.each_with_index do |pagina, index|
        Rails.logger.info "=== FIRMADOR: Procesando documento #{index + 1} ==="
        
        # Insertar CAF en el DD del TED
        insertar_caf(index, pagina[:rango_folio_id])
        
        # Firmar TED con clave privada del CAF
        firmar_ted(index, pagina[:rsask])
        
        # Firmar Documento con certificado de empresa
        firmar_documento(index, certificado)
      end
      
      # 2. Insertar template de firma SetDTE
      Rails.logger.info "=== FIRMADOR: Template firma SetDTE ==="
      firmar_set_dte(certificado)
      
      # 3. Firmar con xmlsec1 (única fuente de SignatureValue); verificación obligatoria
      Rails.logger.info "=== FIRMADOR: Invocando xmlsec1 (sign + verify) ==="
      xml_con_templates = @xml.to_xml(indent: 2, encoding: 'ISO-8859-1')
      resultado_xmlsec = Dte::XmlSignerWithXmlsec.call(xml_string: xml_con_templates, certificado: certificado)

      # XmlSignerWithXmlsec ya validó que ninguna firma esté vacía; no se entrega XML si no es así
      Rails.logger.info "=== FIRMADOR: Firma completada (xmlsec1 OK) ==="
      {
        success: true,
        xml_firmado: resultado_xmlsec[:xml_firmado]
      }
    rescue Dte::XmlSecFirmaIncompletaError => e
      Rails.logger.error "=== FIRMADOR: Firma incompleta (no se entrega XML) ==="
      { success: false, error: e.message }
    rescue Dte::XmlSecVerifyError => e
      Rails.logger.error "=== FIRMADOR: xmlsec1 --verify falló ==="
      raise
    rescue StandardError => e
      Rails.logger.error "=== FIRMADOR ERROR: #{e.message} ==="
      Rails.logger.error e.backtrace.first(5).join("\n")
      { success: false, error: e.message }
    end

    private

    def certificado_para_firma
      return @certificado if @certificado

      resolucion = Certificados::ResolverParaEmpresa.call(empresa_id: @empresa_id)
      unless resolucion.success?
        @error_resolucion_certificado = resolucion.error
        return nil
      end

      @certificado = resolucion.certificado
    end

    # Inserta el nodo CAF en el DD del TED
    def insertar_caf(doc_index, rango_folio_id)
      Rails.logger.info "=== FIRMADOR: Insertando CAF para documento #{doc_index} ==="
      
      # Obtener el rango de folio con el archivo CAF
      rango = RangoFolio.find(rango_folio_id)
      
      unless rango.archivo_rango_folio.attached?
        raise StandardError, "No hay archivo CAF adjunto para el rango #{rango_folio_id}"
      end
      
      # Leer contenido del archivo CAF
      contenido_caf = rango.archivo_rango_folio.download
      
      # Parsear el XML del CAF
      xml_caf = Nokogiri::XML(contenido_caf)
      nodo_caf = xml_caf.xpath('//CAF').first
      
      unless nodo_caf
        raise StandardError, "No se encontró nodo CAF en el archivo"
      end
      
      str_caf = nodo_caf.to_xml(encoding: 'ISO-8859-1')
      fragment = @xml.fragment(str_caf)
      
      # Buscar el nodo TSTED en el DD correspondiente
      tsted_node = @xml.xpath("//xmlns:TED/xmlns:DD/xmlns:TSTED", 'xmlns' => XMLNS_SII)[doc_index]
      
      unless tsted_node
        raise StandardError, "No se encontró nodo TSTED para el documento #{doc_index}"
      end
      
      # Insertar nodo CAF antes de TSTED; la indentación se aplica después al XML completo
      fragment.children.reverse_each { |child| tsted_node.before(child) }

      Rails.logger.info "=== FIRMADOR: CAF insertado para documento #{doc_index} ==="
    end

    # Firma el TED (Timbre Electrónico del DTE) con la clave privada del CAF
    def firmar_ted(doc_index, rsask)
      Rails.logger.info "=== FIRMADOR: Firmando TED #{doc_index} ==="
      
      unless rsask.present?
        raise StandardError, "No se encontró RSASK para firmar el TED"
      end
      
      # Obtener clave privada RSA del CAF (rsask ya viene de la BD)
      priv_key = OpenSSL::PKey::RSA.new(rsask)
      
      # Obtener el nodo DD y canonicalizarlo
      dd_node = @xml.xpath("//xmlns:DD", 'xmlns' => XMLNS_SII)[doc_index]
      dd_canonicalizado = dd_node.canonicalize.force_encoding('ISO-8859-1')
      
      # Firmar con SHA1
      digest = OpenSSL::Digest::SHA1.new
      firma = priv_key.sign(digest, quitar_saltos_linea(dd_canonicalizado))
      firma_base64 = Base64.encode64(firma).gsub("\n", '')
      
      # Insertar firma en FRMT
      frmt_node = @xml.xpath("//xmlns:TED/xmlns:FRMT", 'xmlns' => XMLNS_SII)[doc_index]
      frmt_node.content = firma_base64
      
      Rails.logger.info "=== FIRMADOR: TED #{doc_index} firmado ==="
    end

    # Firma un Documento individual con el certificado de la empresa
    def firmar_documento(doc_index, certificado)
      Rails.logger.info "=== FIRMADOR: Firmando Documento #{doc_index} ==="
      
      # Obtener el nodo Documento
      doc_node = @xml.xpath("//xmlns:Documento", 'xmlns' => XMLNS_SII)[doc_index]
      doc_id = doc_node['ID']
      
      # Calcular DigestValue del Documento canonicalizado
      doc_canonicalizado = doc_node.canonicalize.force_encoding('ISO-8859-1')
      digest_value = calcular_digest(doc_canonicalizado)
      
      # Firma del DTE: hijo directo de <DTE>, inmediatamente después de <Documento> (EnvioDTE_v10.xsd)
      # SignatureValue se rellena con xmlsec1 (no OpenSSL)
      dte_node = doc_node.parent
      insertar_signature_como_hijo(dte_node, "##{doc_id}", digest_value)
      
      Rails.logger.info "=== FIRMADOR: Template firma DTE #{doc_index} insertado ==="
    end

    # Firma el SetDTE completo
    def firmar_set_dte(certificado)
      # Obtener el nodo SetDTE
      set_dte_node = @xml.xpath("//xmlns:SetDTE", 'xmlns' => XMLNS_SII).first
      
      # Calcular DigestValue del SetDTE canonicalizado
      set_dte_canonicalizado = set_dte_node.canonicalize.force_encoding('ISO-8859-1')
      digest_value = calcular_digest(set_dte_canonicalizado)
      
      # Insertar Signature del SetDTE después de cerrar </SetDTE> (como hermano de SetDTE, no dentro)
      # SignatureValue se rellena con xmlsec1 (no OpenSSL)
      insertar_signature_template_after(set_dte_node, "#SetDoc", digest_value)
    end

    # Calcula el DigestValue de un contenido
    def calcular_digest(contenido)
      digester = OpenSSL::Digest::SHA1.new
      digest = digester.digest(contenido)
      Base64.encode64(digest).gsub("\n", '')
    end

    # Inserta Signature como último hijo del nodo (ej.: dentro de <DTE>, después de <Documento>)
    def insertar_signature_como_hijo(parent_node, reference_uri, digest_value)
      signature_xml = construir_signature_xml(reference_uri, digest_value)
      fragment = parent_node.document.fragment(signature_xml)
      parent_node.add_child(fragment.children.first)
    end

    # Inserta Signature después del nodo (ej.: después de </SetDTE>, como hijo de EnvioDTE)
    def insertar_signature_template_after(node, reference_uri, digest_value)
      signature_xml = construir_signature_xml(reference_uri, digest_value)
      node.after(signature_xml)
    end

    # Construye el XML de Signature
    def construir_signature_xml(reference_uri, digest_value)
      <<~XML
        <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
          <SignedInfo>
            <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
            <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
            <Reference URI="#{reference_uri}">
              <Transforms>
                <Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
              </Transforms>
              <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
              <DigestValue>#{digest_value}</DigestValue>
            </Reference>
          </SignedInfo>
          <SignatureValue></SignatureValue>
          <KeyInfo>
            <KeyValue>
              <RSAKeyValue>
                <Modulus></Modulus>
                <Exponent></Exponent>
              </RSAKeyValue>
            </KeyValue>
            <X509Data>
              <X509Certificate></X509Certificate>
            </X509Data>
          </KeyInfo>
        </Signature>
      XML
    end

    # Lee el archivo CAF (desde Active Storage)
    def leer_archivo_caf(archivo_caf)
      Rails.logger.info "=== leer_archivo_caf: tipo = #{archivo_caf.class.name} ==="
      
      if archivo_caf.respond_to?(:download)
        # Es un attachment de Active Storage - usar download
        Rails.logger.info "=== leer_archivo_caf: usando download ==="
        archivo_caf.download
      elsif archivo_caf.respond_to?(:blob) && archivo_caf.blob.respond_to?(:download)
        # Es un attachment con blob
        Rails.logger.info "=== leer_archivo_caf: usando blob.download ==="
        archivo_caf.blob.download
      elsif archivo_caf.is_a?(String) && File.exist?(archivo_caf)
        # Es una ruta de archivo que existe
        Rails.logger.info "=== leer_archivo_caf: leyendo archivo desde ruta ==="
        File.read(archivo_caf)
      else
        raise StandardError, "No se pudo leer el archivo CAF (tipo: #{archivo_caf.class.name})"
      end
    end

    # Quita saltos de línea de un string
    def quitar_saltos_linea(str)
      str.gsub(/\r?\n/, '')
    end
  end
end

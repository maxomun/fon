# frozen_string_literal: true

require 'open3'
require 'nokogiri'
require 'openssl'
require 'base64'

module Dte
  # Firma XMLDSIG usando xmlsec1 (CLI) como única fuente de verdad para SignatureValue.
  # No usa OpenSSL::PKey#sign; la verificación post-firma es obligatoria.
  #
  # --id-attr debe incluir el namespace SII para que xmlsec1 resuelva tanto
  # Reference URI del Documento (#F000...T33) como del SetDTE (#SetDoc).
  #
  # Comandos ejecutados:
  #   xmlsec1 --sign ... --id-attr:ID "http://www.sii.cl/SiiDte:Documento" \
  #          --id-attr:ID "http://www.sii.cl/SiiDte:SetDTE" ...
  #   xmlsec1 --verify ... (mismos id-attr) ...
  #
  # Tras firmar y verificar, se valida que ninguna Signature tenga SignatureValue
  # o X509Certificate vacíos; si alguna está vacía se lanza XmlSecFirmaIncompletaError.
  #
  # Si xmlsec1 no rellena la firma del sobre (#SetDoc), se rellena en Ruby con la misma clave.
  class XmlSignerWithXmlsec
    XMLNS_SII = 'http://www.sii.cl/SiiDte'
    XMLNS_DS = 'http://www.w3.org/2000/09/xmldsig#'
    # namespace:localname para que xmlsec1 resuelva Reference URI en elementos del SII
    ID_ATTR_DOCUMENTO = "#{XMLNS_SII}:Documento"
    ID_ATTR_SETDTE = "#{XMLNS_SII}:SetDTE"

    def self.call(xml_string:, certificado:)
      new(xml_string: xml_string, certificado: certificado).call
    end

    def initialize(xml_string:, certificado:)
      @xml_string = xml_string
      @certificado = certificado
    end

    def call
      validar_credenciales!
      Dir.mktmpdir('xmlsec_dte') do |dir|
        template_path = File.join(dir, 'envio_dte.xml')
        signed_path = File.join(dir, 'envio_dte_signed.xml')
        key_path = File.join(dir, 'privkey.pem')
        cert_path = File.join(dir, 'cert.pem')

        File.write(template_path, @xml_string, encoding: 'ISO-8859-1')
        escribir_credenciales(key_path, cert_path)
        firmar_con_xmlsec(template_path, signed_path, key_path, cert_path)
        xml_firmado = File.read(signed_path, encoding: 'ISO-8859-1')
        xml_firmado = rellenar_firma_setdoc_si_vacia!(xml_firmado, key_path, cert_path)
        File.write(signed_path, xml_firmado, encoding: 'ISO-8859-1')
        verificar_con_xmlsec(signed_path)
        validar_firmas_no_vacias!(xml_firmado)
        { xml_firmado: xml_firmado }
      end
    end

    private

    def validar_credenciales!
      raise ArgumentError, 'Certificado no disponible' unless @certificado
      raise ArgumentError, 'Certificado incompleto (falta .crt o .key)' unless @certificado.completo?
      return if contenido_key.present? && contenido_cert.present?

      raise ArgumentError, 'No se pudo leer contenido de certificado o clave privada'
    end

    def contenido_cert
      @contenido_cert ||= @certificado.archivo_crs.attached? ? @certificado.archivo_crs.download : nil
    end

    def contenido_key
      @contenido_key ||= @certificado.archivo_key.attached? ? @certificado.archivo_key.download : nil
    end

    def escribir_credenciales(key_path, cert_path)
      File.binwrite(key_path, contenido_key)
      File.binwrite(cert_path, contenido_cert)
      File.chmod(0o600, key_path)
    end

    # Firmar todas las Signature del documento con xmlsec1 (DTE + SetDTE)
    # --id-attr necesario para que xmlsec resuelva Reference URI (id('F000...T33'), id('SetDoc'))
    def firmar_con_xmlsec(template_path, signed_path, key_path, cert_path)
      cmd = [
        'xmlsec1',
        '--sign',
        '--output', signed_path,
        '--id-attr:ID', ID_ATTR_DOCUMENTO,
        '--id-attr:ID', ID_ATTR_SETDTE,
        '--privkey-pem', "#{key_path},#{cert_path}",
        template_path
      ]
      out, err, status = ejecutar(cmd)
      raise "xmlsec1 --sign falló (exit #{status}): #{out} #{err}" unless status.success?
    end

    # Verificación obligatoria; falla el proceso si no pasa
    def verificar_con_xmlsec(signed_path)
      cmd = [
        'xmlsec1',
        '--verify',
        '--id-attr:ID', ID_ATTR_DOCUMENTO,
        '--id-attr:ID', ID_ATTR_SETDTE,
        signed_path
      ]
      out, err, status = ejecutar(cmd)
      return if status.success?

      msg = "xmlsec1 --verify falló (exit #{status.exitstatus}). stdout: #{out}. stderr: #{err}"
      raise XmlSecVerifyError, msg
    end

    # Rellena en Ruby la firma del SetDTE (Reference #SetDoc) si xmlsec1 la dejó vacía.
    # Usa reemplazo en el string para no alterar el resto del XML y que xmlsec1 --verify siga pasando.
    # Devuelve el XML como string (modificado si hizo falta rellenar).
    def rellenar_firma_setdoc_si_vacia!(xml_string, key_path, cert_path)
      doc = Nokogiri::XML(xml_string)
      sig_setdoc = nil
      doc.xpath("//ds:Signature", 'ds' => XMLNS_DS).each do |sig|
        ref_uri = sig.xpath('ds:SignedInfo/ds:Reference/@URI', 'ds' => XMLNS_DS).first&.value
        next unless ref_uri == '#SetDoc'

        sv_node = sig.xpath('ds:SignatureValue', 'ds' => XMLNS_DS).first
        next if sv_node.nil? || sv_node.text.to_s.strip.present?

        sig_setdoc = sig
        break
      end
      return xml_string if sig_setdoc.nil?

      # Calcular firma y KeyInfo con OpenSSL
      priv_key = OpenSSL::PKey::RSA.new(File.read(key_path))
      cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
      signed_info = sig_setdoc.xpath('ds:SignedInfo', 'ds' => XMLNS_DS).first
      raise XmlSecFirmaIncompletaError, 'No se encontró SignedInfo en la firma SetDoc' if signed_info.nil?

      c14n = signed_info.canonicalize
      data = c14n.force_encoding('ISO-8859-1')
      signature = priv_key.sign(OpenSSL::Digest::SHA1.new, data)
      sig_value_b64 = Base64.encode64(signature).gsub("\n", '')
      rsa = cert.public_key
      mod_b64 = Base64.strict_encode64(int_to_be_bytes(rsa.n)).gsub("\n", '')
      exp_b64 = Base64.strict_encode64(int_to_be_bytes(rsa.e)).gsub("\n", '')
      cert_b64 = Base64.strict_encode64(cert.to_der).gsub("\n", '')

      # Reemplazar solo los valores vacíos del segundo bloque Signature (después de </SetDTE>) para no romper --verify
      idx_after_setdte = xml_string.index('</SetDTE>')
      return xml_string if idx_after_setdte.nil?

      remainder = xml_string[idx_after_setdte..]
      remainder = remainder.sub(%r{<SignatureValue>\s*</SignatureValue>}, "<SignatureValue>#{sig_value_b64}</SignatureValue>")
      remainder = remainder.sub(%r{<SignatureValue\s*/>}, "<SignatureValue>#{sig_value_b64}</SignatureValue>")
      remainder = remainder.sub(%r{<Modulus>\s*</Modulus>}, "<Modulus>#{mod_b64}</Modulus>")
      remainder = remainder.sub(%r{<Modulus\s*/>}, "<Modulus>#{mod_b64}</Modulus>")
      remainder = remainder.sub(%r{<Exponent>\s*</Exponent>}, "<Exponent>#{exp_b64}</Exponent>")
      remainder = remainder.sub(%r{<Exponent\s*/>}, "<Exponent>#{exp_b64}</Exponent>")
      remainder = remainder.sub(%r{<X509Certificate>\s*</X509Certificate>}, "<X509Certificate>#{cert_b64}</X509Certificate>")
      remainder = remainder.sub(%r{<X509Certificate\s*/>}, "<X509Certificate>#{cert_b64}</X509Certificate>")
      xml_string[0...idx_after_setdte] + remainder
    end

    def int_to_be_bytes(n)
      n = n.to_i if n.respond_to?(:to_i)
      return '' if n.nil? || n <= 0
      bytes = []
      while n.positive?
        bytes.unshift(n & 0xFF)
        n >>= 8
      end
      bytes.pack('C*')
    end

    # Asegura que ninguna firma quede con SignatureValue o X509Certificate vacíos.
    # Si alguna está vacía, lanza XmlSecFirmaIncompletaError (no se debe entregar XML).
    def validar_firmas_no_vacias!(xml_string)
      doc = Nokogiri::XML(xml_string)
      doc.xpath("//ds:Signature", 'ds' => XMLNS_DS).each_with_index do |sig, idx|
        sv = sig.xpath('ds:SignatureValue', 'ds' => XMLNS_DS).first
        cert = sig.xpath('ds:KeyInfo/ds:X509Data/ds:X509Certificate', 'ds' => XMLNS_DS).first
        ref_uri = sig.xpath('ds:SignedInfo/ds:Reference/@URI', 'ds' => XMLNS_DS).first&.value
        if sv.nil? || sv.text.to_s.strip.empty?
          raise XmlSecFirmaIncompletaError,
                "Firma ##{idx + 1} (Reference URI=#{ref_uri}) tiene SignatureValue vacío. " \
                "El firmado del documento no se completó correctamente."
        end
        if cert.nil? || cert.text.to_s.strip.empty?
          raise XmlSecFirmaIncompletaError,
                "Firma ##{idx + 1} (Reference URI=#{ref_uri}) tiene X509Certificate vacío. " \
                "El firmado del documento no se completó correctamente."
        end
      end
    end

    def ejecutar(cmd)
      out = nil
      err = nil
      status = nil
      Open3.popen3(*cmd) do |_stdin, stdout, stderr, wait_thr|
        out = stdout.read
        err = stderr.read
        status = wait_thr.value
      end
      [out, err, status]
    end
  end

  class XmlSecVerifyError < StandardError; end

  # Se lanza cuando xmlsec1 deja alguna Signature con SignatureValue o KeyInfo vacíos.
  # No se debe entregar XML en ese caso.
  class XmlSecFirmaIncompletaError < StandardError; end
end

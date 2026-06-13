# frozen_string_literal: true

class Certificado < ApplicationRecord
  self.table_name = 'certificados'

  # Relaciones
  belongs_to :user

  # Active Storage - Archivos del certificado
  # archivo_crs: Certificado público (.crt o .pem)
  # archivo_key: Clave privada (.key o .pem)
  #
  # Para generar desde un .pfx/.p12:
  #   openssl pkcs12 -in certificado.pfx -out certificado.crt -nokeys -clcerts
  #   openssl pkcs12 -in certificado.pfx -out certificado.key -nocerts -nodes
  #
  has_one_attached :archivo_crs
  has_one_attached :archivo_key

  # Validaciones
  validates :vigente, inclusion: { in: [true, false] }
  validates :responsable, length: { maximum: 100 }, allow_blank: true
  validates :frase_clave, length: { maximum: 1000 }, allow_blank: true

  # Scopes
  scope :vigentes, -> { where(vigente: true) }
  scope :caducados, -> { where(vigente: false) }

  # Métodos
  def caducado?
    return false if fecha_caducacion.nil?

    fecha_caducacion < Time.current
  end

  # Verifica si el certificado tiene los archivos necesarios para firmar
  def completo?
    archivo_crs.attached? && archivo_key.attached?
  end

  # Lee el contenido del archivo .crt
  def contenido_crs
    return nil unless archivo_crs.attached?

    File.read(ActiveStorage::Blob.service.path_for(archivo_crs.key))
  end

  # Lee el contenido del archivo .key
  def contenido_key
    Rails.logger.info "=== contenido_key: inicio ==="
    return nil unless archivo_key.attached?
    
    Rails.logger.info "=== contenido_key: archivo_key.key = #{archivo_key.key} ==="
    path = ActiveStorage::Blob.service.path_for(archivo_key.key)
    Rails.logger.info "=== contenido_key: path = #{path} ==="
    Rails.logger.info "=== contenido_key: File.exist? = #{File.exist?(path)} ==="
    
    File.read(path)
  end

  # Obtiene la clave privada como objeto OpenSSL
  # Intenta primero sin frase clave (para archivos generados con -nodes)
  # y luego con frase clave si está presente
  def clave_privada
    Rails.logger.info "=== clave_privada: inicio ==="
    return nil unless archivo_key.attached?
    Rails.logger.info "=== clave_privada: archivo_key attached ==="

    contenido = contenido_key
    Rails.logger.info "=== clave_privada: contenido obtenido (#{contenido&.bytesize} bytes) ==="
    return nil unless contenido

    # Intentar sin frase clave primero (archivo no encriptado)
    begin
      Rails.logger.info "=== clave_privada: intentando sin frase clave ==="
      key = OpenSSL::PKey::RSA.new(contenido)
      Rails.logger.info "=== clave_privada: OK sin frase clave ==="
      return key
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.info "=== clave_privada: falló sin frase clave: #{e.message} ==="
    end

    # Intentar con frase clave
    if frase_clave.present?
      begin
        Rails.logger.info "=== clave_privada: intentando con frase clave ==="
        key = OpenSSL::PKey::RSA.new(contenido, frase_clave)
        Rails.logger.info "=== clave_privada: OK con frase clave ==="
        return key
      rescue OpenSSL::PKey::RSAError => e
        Rails.logger.error("Error al cargar clave privada con frase clave: #{e.message}")
      end
    end

    Rails.logger.info "=== clave_privada: retornando nil ==="
    nil
  end

  # Obtiene el certificado X509
  def certificado_x509
    return nil unless archivo_crs.attached?

    OpenSSL::X509::Certificate.new(contenido_crs)
  rescue OpenSSL::X509::CertificateError => e
    Rails.logger.error("Error al cargar certificado: #{e.message}")
    nil
  end

  # Extrae el X509Certificate limpio en Base64 (para insertar en XML)
  # OpenSSL ignora metadata extra y lee solo el bloque del certificado
  def x509_sin_headers
    cert = certificado_x509
    return nil unless cert

    # to_der convierte a binario DER, strict_encode64 lo codifica sin saltos de línea
    Base64.strict_encode64(cert.to_der)
  end
end

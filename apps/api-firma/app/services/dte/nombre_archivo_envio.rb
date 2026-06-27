# frozen_string_literal: true

module Dte
  # Nombre de archivo para el XML firmado de un envío DTE (descarga y archivado).
  #
  # Formato: envio_{id}_dte_{tipo}_folio_{n}_{rut}_{fecha}.xml
  # Ejemplo: envio_1_dte_33_folio_45_76123456-7_20260627.xml
  # Varios folios: envio_2_dte_33_folios_45-47_76123456-7_20260627.xml
  class NombreArchivoEnvio
    def self.for_envio(dte_envio:, empresa:, tipo_documento: nil, folios: nil, documentos: nil)
      new(
        dte_envio: dte_envio,
        empresa: empresa,
        tipo_documento: tipo_documento,
        folios: folios,
        documentos: documentos
      ).to_s
    end

    def initialize(dte_envio:, empresa:, tipo_documento: nil, folios: nil, documentos: nil)
      @dte_envio = dte_envio
      @empresa = empresa
      @tipo_documento = tipo_documento
      @folios = folios
      @documentos = documentos
    end

    def to_s
      "#{prefijo}_#{etiqueta_folios}_#{rut_limpio}_#{fecha}.xml"
    end

    private

    attr_reader :dte_envio, :empresa, :tipo_documento, :folios, :documentos

    def prefijo
      "envio_#{dte_envio.id}_dte_#{codigo_tipo_documento}"
    end

    def codigo_tipo_documento
      return tipo_documento.to_s if tipo_documento.present?

      documentos&.first&.tipo_documento_codigo.to_s.presence || 'dte'
    end

    def numeros_folio
      Array(folios).presence || documentos&.map(&:folio)&.sort || []
    end

    def etiqueta_folios
      nums = numeros_folio
      return 'folio_sin_numero' if nums.empty?

      nums.one? ? "folio_#{nums.first}" : "folios_#{nums.join('-')}"
    end

    def rut_limpio
      empresa.rut.to_s.gsub(/[.\s]/, '')
    end

    def fecha
      (dte_envio.created_at || Time.current).strftime('%Y%m%d')
    end
  end
end

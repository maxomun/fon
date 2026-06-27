# frozen_string_literal: true

require 'stringio'

module Dte
  # Persiste el EnvioDTE firmado en Active Storage y enlaza los documento_emitidos del lote.
  class ArchivadorXml
    ATTACHMENT_NAME = 'xml_firmado'

    def self.call(**params)
      new(**params).call
    end

    # Elimina el XML sin usar purge (evita active_storage_variant_records, no usada aquí).
    def self.eliminar_adjunto(dte_envio)
      attachment = ActiveStorage::Attachment.find_by(
        record_type: dte_envio.class.name,
        record_id: dte_envio.id,
        name: ATTACHMENT_NAME
      )
      return unless attachment

      blob = attachment.blob
      attachment.delete

      return if ActiveStorage::Attachment.exists?(blob_id: blob.id)

      blob.service.delete(blob.key)
      ActiveStorage::Blob.where(id: blob.id).delete_all
    end

    def initialize(empresa:, usuario:, tipo_documento:, xml_firmado:, documentos:, folios:)
      @empresa = empresa
      @usuario = usuario
      @tipo_documento = tipo_documento
      @xml_firmado = xml_firmado
      @documentos = documentos
      @folios = folios
    end

    def call
      dte_envio = DteEnvio.create!(
        empresa_id: empresa.id,
        usuario_id: usuario.id
      )

      nombre = NombreArchivoEnvio.for_envio(
        dte_envio: dte_envio,
        empresa: empresa,
        tipo_documento: tipo_documento,
        folios: folios
      )

      dte_envio.xml_firmado.attach(
        io: StringIO.new(xml_firmado),
        filename: nombre,
        content_type: 'application/xml'
      )

      unless dte_envio.xml_firmado.attached?
        raise StandardError, 'No se pudo adjuntar el XML firmado'
      end

      documentos.each do |documento|
        documento.update!(dte_envio_id: dte_envio.id)
      end

      { success: true, dte_envio: dte_envio }
    rescue ActiveRecord::RecordInvalid, StandardError => e
      { success: false, error: e.message }
    end

    private

    attr_reader :empresa, :usuario, :tipo_documento, :xml_firmado, :documentos, :folios
  end
end

# frozen_string_literal: true

module Dte
  # Elimina un envío DTE de prueba, sus documentos asociados y libera los folios usados.
  # Uso exclusivo de administrador FON para repetir certificación.
  class LimpiadorEnvio
    def self.call(dte_envio:)
      new(dte_envio: dte_envio).call
    end

    def initialize(dte_envio:)
      @dte_envio = dte_envio
    end

    def call
      documentos = dte_envio.documento_emitidos.includes(:tipo_habilitado).order(:id).to_a
      return resultado_sin_documentos if documentos.empty?

      validacion = validar_documentos(documentos)
      return validacion unless validacion[:success]

      folios_liberados = []
      documento_ids = documentos.map(&:id)
      dte_envio_id = dte_envio.id

      ActiveRecord::Base.transaction do
        documentos.each do |documento|
          folio_liberado = liberar_folio(documento)
          folios_liberados << folio_liberado if folio_liberado
          eliminar_pdf(documento)
          documento.destroy!
        end

        ArchivadorXml.eliminar_adjunto(dte_envio)
        dte_envio.destroy!
      end

      {
        success: true,
        dte_envio_id: dte_envio_id,
        documentos_eliminados: documento_ids.count,
        folios_liberados: folios_liberados.uniq.sort,
        documento_ids: documento_ids
      }
    rescue ActiveRecord::RecordNotDestroyed => e
      { success: false, error: e.message, code: 'DELETE_RESTRICTED' }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message, code: 'VALIDATION_ERROR' }
    end

    private

    attr_reader :dte_envio

    def resultado_sin_documentos
      folios_liberados = []
      dte_envio_id = dte_envio.id

      ActiveRecord::Base.transaction do
        ArchivadorXml.eliminar_adjunto(dte_envio)
        dte_envio.destroy!
      end

      {
        success: true,
        dte_envio_id: dte_envio_id,
        documentos_eliminados: 0,
        folios_liberados: folios_liberados,
        documento_ids: []
      }
    rescue ActiveRecord::RecordNotDestroyed => e
      { success: false, error: e.message, code: 'DELETE_RESTRICTED' }
    end

    def validar_documentos(documentos)
      if documentos.any? { |documento| !documento.ingreso_autonomo }
        return {
          success: false,
          error: 'Solo se pueden limpiar documentos emitidos de forma autónoma (pruebas)',
          code: 'NOT_AUTONOMO'
        }
      end

      if DocumentoEmitido.where(asociado_id: documentos.map(&:id)).exists?
        return {
          success: false,
          error: 'El envío tiene documentos referenciados por notas de crédito o débito',
          code: 'DOCUMENTOS_ASOCIADOS'
        }
      end

      { success: true }
    end

    def liberar_folio(documento)
      folio = Folio.find_by(
        tipo_habilitado_id: documento.tipo_habilitado_id,
        numero: documento.folio
      )
      return nil unless folio&.usado?

      folio.liberar_uso!
      documento.folio
    end

    def eliminar_pdf(documento)
      return unless documento.pdf.attached?

      ActiveStorage::EliminadorSinPurge.call(record: documento, name: :pdf)
      documento.reload
    end
  end
end

# frozen_string_literal: true

module ActiveStorage
  # Elimina un adjunto y su blob sin encolar PurgeJob (evita variant_records y jobs async).
  class EliminadorSinPurge
    def self.call(record:, name:)
      new(record: record, name: name).call
    end

    def initialize(record:, name:)
      @record = record
      @name = name
    end

    def call
      attachment = ActiveStorage::Attachment.find_by(
        record_type: record.class.name,
        record_id: record.id,
        name: name.to_s
      )
      return unless attachment

      blob = attachment.blob
      attachment.delete

      return if ActiveStorage::Attachment.exists?(blob_id: blob.id)

      blob.service.delete(blob.key)
      ActiveStorage::Blob.where(id: blob.id).delete_all
    end

    private

    attr_reader :record, :name
  end
end

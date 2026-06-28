# frozen_string_literal: true

class CreateActiveStorageVariantRecords < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:active_storage_variant_records)

    create_table :active_storage_variant_records, id: primary_key_type do |t|
      t.belongs_to :blob, null: false, index: false, type: foreign_key_type
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest],
              name: 'index_active_storage_variant_records_uniqueness',
              unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end

  private

  def primary_key_type
    primary_key_type = config.options[config.orm][:primary_key_type]
    primary_key_type || :primary_key
  end

  def foreign_key_type
    foreign_key_type = config.options[config.orm][:primary_key_type]
    foreign_key_type || :bigint
  end

  def config
    Rails.configuration.generators
  end
end

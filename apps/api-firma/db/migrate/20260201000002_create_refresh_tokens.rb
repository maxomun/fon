# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.string :token, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end

    # Índices para búsquedas frecuentes
    add_index :refresh_tokens, :expires_at
    add_index :refresh_tokens, [:user_id, :revoked_at]
  end
end

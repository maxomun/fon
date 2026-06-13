# frozen_string_literal: true

class CreateTokenBlacklists < ActiveRecord::Migration[7.1]
  def change
    create_table :token_blacklists do |t|
      t.string :jti, null: false, index: { unique: true }
      t.datetime :exp, null: false
      t.references :user, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Índice para limpiar tokens expirados
    add_index :token_blacklists, :exp
  end
end

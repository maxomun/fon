# frozen_string_literal: true

class CreateDocumentoDescuentosRecargosGlobales < ActiveRecord::Migration[7.1]
  def change
    create_table :documento_descuentos_recargos_globales, comment: 'Descuentos/recargos globales DTE por documento emitido (SII DscRcgGlobal).' do |t|
      t.integer :documento_emitido_id, null: false, comment: 'Documento al que pertenece el movimiento global.'
      t.integer :nro_linea, null: false, comment: 'Correlativo 1-20 dentro del documento (NroLinDR).'
      t.string :tipo_movimiento, limit: 1, null: false, comment: 'D = descuento, R = recargo.'
      t.string :glosa, limit: 250, null: false, comment: 'GlosaDR del movimiento.'
      t.string :tipo_valor, limit: 20, null: false, comment: 'PORCENTAJE o MONTO.'
      t.decimal :valor, precision: 15, scale: 4, null: false, comment: 'ValorDR (% o monto fijo).'
      t.string :aplica_sobre, limit: 30, null: false, comment: 'AFECTO | EXENTO_NO_AFECTO | NO_FACTURABLE.'
      t.integer :monto_calculado, null: false, comment: 'Monto aplicado sobre la base correspondiente.'
      t.integer :orden, null: false, comment: 'Orden de aplicación en el documento.'

      t.index :documento_emitido_id, name: 'idx_doc_dr_globales_documento'
      t.index [:documento_emitido_id, :nro_linea], unique: true, name: 'uq_doc_dr_globales_documento_nro_linea'
    end

    add_foreign_key :documento_descuentos_recargos_globales, :documento_emitidos,
                    name: 'fk_doc_dr_globales_documento_emitidos',
                    on_delete: :cascade
  end
end

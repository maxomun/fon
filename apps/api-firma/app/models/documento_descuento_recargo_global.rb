# frozen_string_literal: true

class DocumentoDescuentoRecargoGlobal < ApplicationRecord
  self.table_name = 'documento_descuentos_recargos_globales'

  belongs_to :documento_emitido

  validates :nro_linea, presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 20 }
  validates :tipo_movimiento, presence: true,
            inclusion: { in: [Dte::DescuentosRecargos::Constants::TPO_MOV_DESCUENTO,
                              Dte::DescuentosRecargos::Constants::TPO_MOV_RECARGO] }
  validates :glosa, presence: true, length: { maximum: 250 }
  validates :tipo_valor, presence: true,
            inclusion: { in: [Dte::DescuentosRecargos::Constants::TIPO_VALOR_PORCENTAJE,
                              Dte::DescuentosRecargos::Constants::TIPO_VALOR_MONTO] }
  validates :valor, presence: true, numericality: { greater_than: 0 }
  validates :aplica_sobre, presence: true,
            inclusion: { in: Dte::DescuentosRecargos::Constants::AMBITOS_MONTO }
  validates :monto_calculado, presence: true, numericality: { only_integer: true }
  validates :orden, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :nro_linea, uniqueness: { scope: :documento_emitido_id }

  scope :ordenados, -> { order(:orden, :nro_linea) }

  def self.crear_desde_hash!(documento_emitido:, movimiento:)
    create!(
      documento_emitido: documento_emitido,
      nro_linea: movimiento[:nro_linea] || movimiento['nro_linea'],
      tipo_movimiento: movimiento[:tipo_movimiento] || movimiento['tipo_movimiento'],
      glosa: movimiento[:glosa] || movimiento['glosa'],
      tipo_valor: movimiento[:tipo_valor] || movimiento['tipo_valor'],
      valor: movimiento[:valor] || movimiento['valor'],
      aplica_sobre: movimiento[:aplica_sobre] || movimiento['aplica_sobre'],
      monto_calculado: movimiento[:monto_calculado] || movimiento['monto_calculado'],
      orden: movimiento[:orden] || movimiento['orden']
    )
  end
end

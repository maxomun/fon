# frozen_string_literal: true

module ImpuestoSerializable
  extend ActiveSupport::Concern

  private

  def impuesto_payload(impuesto, include_valores: false)
    payload = {
      id: impuesto.id,
      pais_id: impuesto.pais_id,
      pais: {
        id: impuesto.pais.id,
        codigo: impuesto.pais.codigo,
        nombre: impuesto.pais.nombre
      },
      nombre: impuesto.nombre,
      abreviacion: impuesto.abreviacion,
      valor_vigente: impuesto.valor_vigente,
      tiene_productos: impuesto.tiene_productos?
    }

    if include_valores
      payload[:valores] = impuesto.impuesto_valores.ordenados.map do |valor|
        impuesto_valor_payload(valor)
      end
    end

    payload
  end

  def impuesto_valor_payload(valor)
    {
      id: valor.id,
      impuesto_id: valor.impuesto_id,
      valor: valor.valor,
      fecha_activacion: valor.fecha_activacion,
      fecha_caducacion: valor.fecha_caducacion,
      vigente: valor.vigente?
    }
  end

  def render_impuesto_validation_error(record)
    render_error(
      'Error de validación',
      :unprocessable_entity,
      code: 'VALIDATION_ERROR',
      errors: record.errors.full_messages
    )
  end
end

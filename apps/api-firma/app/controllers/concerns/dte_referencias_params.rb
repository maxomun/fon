# frozen_string_literal: true

module DteReferenciasParams
  extend ActiveSupport::Concern

  private

  def referencias_raw
    params[:referencias] || params['referencias']
  end

  def resultado_validacion_referencias
    return @resultado_validacion_referencias if defined?(@resultado_validacion_referencias)

    @resultado_validacion_referencias =
      if referencias_raw.nil?
        { success: true, referencias: [] }
      else
        Dte::Referencias::Validador.call(
          raw: referencias_raw,
          tipo_documento_emision: params[:tipo_documento] || params['tipo_documento'],
          empresa_id: params[:empresa_id] || params['empresa_id']
        )
      end
  end

  def errores_referencias_dte
    return [] if referencias_raw.nil?

    resultado = resultado_validacion_referencias
    resultado[:success] ? [] : resultado[:errors]
  end

  def referencias_normalizadas
    resultado = resultado_validacion_referencias
    resultado[:success] ? resultado[:referencias] : []
  end
end

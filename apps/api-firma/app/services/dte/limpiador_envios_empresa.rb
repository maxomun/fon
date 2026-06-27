# frozen_string_literal: true

module Dte
  # Limpia todos los envíos DTE de una empresa (certificación / pruebas repetidas).
  class LimpiadorEnviosEmpresa
    def self.call(empresa:)
      new(empresa: empresa).call
    end

    def initialize(empresa:)
      @empresa = empresa
    end

    def call
      envios = empresa.dte_envios.order(created_at: :desc).to_a
      limpiados = []
      errores = []

      envios.each do |envio|
        resultado = LimpiadorEnvio.call(dte_envio: envio)
        if resultado[:success]
          limpiados << resultado
        else
          errores << {
            dte_envio_id: envio.id,
            error: resultado[:error],
            code: resultado[:code]
          }
        end
      end

      folios_liberados = limpiados.flat_map { |item| item[:folios_liberados] }.uniq.sort
      documentos_eliminados = limpiados.sum { |item| item[:documentos_eliminados] }

      {
        success: errores.empty? || limpiados.any?,
        envios_limpiados: limpiados.count,
        documentos_eliminados: documentos_eliminados,
        folios_liberados: folios_liberados,
        errores: errores
      }
    end

    private

    attr_reader :empresa
  end
end

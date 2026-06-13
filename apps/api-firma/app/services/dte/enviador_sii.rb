# frozen_string_literal: true

module Dte
  # Envía el EnvioDTE firmado al SII (token + upload multipart).
  # Pendiente de implementación completa; la interfaz ya está definida para generar.
  class EnviadorSii
    def self.call(**params)
      new(**params).call
    end

    def initialize(xml_firmado:, empresa_id:, certificado:)
      @xml_firmado = xml_firmado
      @empresa_id = empresa_id
      @certificado = certificado
    end

    def call
      Rails.logger.info "=== ENVIADOR SII: pendiente de implementación (empresa #{empresa_id}) ==="

      {
        success: false,
        pendiente: true,
        error: 'Envío al SII pendiente de implementación',
        track_id: nil
      }
    end

    private

    attr_reader :xml_firmado, :empresa_id, :certificado
  end
end

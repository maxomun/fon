# frozen_string_literal: true

# Configuración del Servicio de Impuestos Internos (SII) de Chile
# para la generación y envío de Documentos Tributarios Electrónicos (DTE)

Rails.application.config.sii = ActiveSupport::OrderedOptions.new

# Ambiente: 'certificacion' o 'produccion'
Rails.application.config.sii.ambiente = ENV.fetch('SII_AMBIENTE', 'certificacion')

# URLs según ambiente
if Rails.application.config.sii.ambiente == 'produccion'
  # Ambiente de Producción (palena)
  Rails.application.config.sii.url_upload = 'https://palena.sii.cl/cgi_dte/UPL/DTEUpload'
  Rails.application.config.sii.url_token = 'https://palena.sii.cl/DTEWS/GetTokenFromSeed.jws'
  Rails.application.config.sii.url_seed = 'https://palena.sii.cl/DTEWS/CrSeed.jws'
else
  # Ambiente de Certificación (maullin)
  Rails.application.config.sii.url_upload = 'https://maullin.sii.cl/cgi_dte/UPL/DTEUpload'
  Rails.application.config.sii.url_token = 'https://maullin.sii.cl/DTEWS/GetTokenFromSeed.jws'
  Rails.application.config.sii.url_seed = 'https://maullin.sii.cl/DTEWS/CrSeed.jws'
end

# Zona horaria para timestamps del DTE
Rails.application.config.sii.timezone = 'America/Santiago'

# frozen_string_literal: true

# Configuración de JWT
# Las constantes están definidas en app/services/json_web_token.rb
#
# Variables de entorno opcionales:
#   JWT_SECRET_KEY - Clave secreta para firmar tokens (usa credentials.secret_key_base por defecto)
#
# Tiempos de expiración (configurables en json_web_token.rb):
#   ACCESS_TOKEN_EXPIRY  = 1.hour   - Token de acceso
#   REFRESH_TOKEN_EXPIRY = 7.days   - Token de refresco
#
# Para producción, asegúrate de:
#   1. Configurar una clave secreta fuerte en credentials o ENV
#   2. Usar HTTPS para transmitir tokens
#   3. Ejecutar limpieza periódica de tokens expirados:
#      TokenBlacklist.cleanup_expired!
#      RefreshToken.cleanup_expired!

# frozen_string_literal: true

namespace :tokens do
  desc 'Limpia tokens expirados de la blacklist y refresh tokens'
  task cleanup: :environment do
    puts "Limpiando tokens expirados..."

    blacklist_count = TokenBlacklist.expired.count
    TokenBlacklist.cleanup_expired!
    puts "  - #{blacklist_count} tokens eliminados de blacklist"

    refresh_count = RefreshToken.expired.count
    RefreshToken.cleanup_expired!
    puts "  - #{refresh_count} refresh tokens eliminados"

    puts "Limpieza completada."
  end

  desc 'Revoca todos los tokens de un usuario específico'
  task :revoke_user, [:user_id] => :environment do |_t, args|
    user_id = args[:user_id]

    if user_id.blank?
      puts "Error: Debes proporcionar un user_id"
      puts "Uso: rails tokens:revoke_user[123]"
      exit 1
    end

    user = User.find_by(id: user_id)

    if user.nil?
      puts "Error: Usuario con ID #{user_id} no encontrado"
      exit 1
    end

    RefreshToken.revoke_all_for_user!(user_id)
    puts "Todos los refresh tokens del usuario #{user.username} (ID: #{user_id}) han sido revocados."
  end

  desc 'Muestra estadísticas de tokens'
  task stats: :environment do
    puts "=== Estadísticas de Tokens ==="
    puts ""
    puts "Blacklist:"
    puts "  - Total: #{TokenBlacklist.count}"
    puts "  - Activos: #{TokenBlacklist.active.count}"
    puts "  - Expirados: #{TokenBlacklist.expired.count}"
    puts ""
    puts "Refresh Tokens:"
    puts "  - Total: #{RefreshToken.count}"
    puts "  - Activos: #{RefreshToken.active.count}"
    puts "  - Expirados: #{RefreshToken.expired.count}"
    puts "  - Revocados: #{RefreshToken.revoked.count}"
  end
end

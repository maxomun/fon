# frozen_string_literal: true

namespace :personas_autorizadas do
  desc 'Provisiona usuarios para personas autorizadas sin user_id (DRY_RUN=1, SOLO_ACTIVAS=1)'
  task backfill_usuarios: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    solo_activas = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SOLO_ACTIVAS', false))

    puts '=== Backfill de usuarios para personas autorizadas ==='
    puts "Modo: #{dry_run ? 'DRY RUN (sin cambios)' : 'EJECUCIÓN REAL'}"
    puts "Alcance: #{solo_activas ? 'solo activas' : 'activas e inactivas'}"
    puts ''

    pendientes_inicial = PersonaAutorizada.where(user_id: nil).count
    pendientes_scope = PersonaAutorizada.where(user_id: nil)
    pendientes_scope = pendientes_scope.activas if solo_activas
    pendientes_filtradas = pendientes_scope.count

    puts "Personas sin user_id (total): #{pendientes_inicial}"
    puts "Personas a procesar en esta corrida: #{pendientes_filtradas}"
    puts ''

    if pendientes_filtradas.zero?
      puts 'No hay personas pendientes. Nada que hacer.'
      next
    end

    if !dry_run && ENV.fetch(PersonasAutorizadas::ProvisionarUsuario::DEFAULT_PASSWORD_ENV, nil).blank?
      puts 'Error: configure PERSONA_AUTORIZADA_DEFAULT_PASSWORD antes de ejecutar el backfill.'
      exit 1
    end

    resultado = PersonasAutorizadas::BackfillUsuarios.call(
      dry_run: dry_run,
      solo_activas: solo_activas
    )

    puts '--- Resultado ---'
    puts "Procesadas: #{resultado.procesadas}"
    puts "Exitosas:   #{resultado.exitosas}"
    puts "  Creadas:    #{resultado.creadas}"
    puts "  Vinculadas: #{resultado.vinculadas}"
    puts "Fallidas:   #{resultado.fallidas}"
    puts "Pendientes sin user_id (total BD): #{resultado.pendientes}"

    if resultado.errores.any?
      puts ''
      puts '--- Errores ---'
      resultado.errores.each do |error|
        puts "  Persona ##{error.persona_id} (#{error.rut}, #{error.email}): #{error.errors.join('; ')}"
      end
    end

    puts ''
    if dry_run
      puts 'Dry run completado. Ejecute sin DRY_RUN=1 para aplicar cambios.'
    elsif resultado.success?
      puts 'Backfill completado sin errores.'
    else
      puts 'Backfill completado con errores. Revise los casos listados arriba.'
      exit 1
    end
  end

  desc 'Muestra cuántas personas autorizadas siguen sin user_id'
  task usuarios_pendientes: :environment do
    total = PersonaAutorizada.where(user_id: nil).count
    activas = PersonaAutorizada.where(user_id: nil).activas.count
    inactivas = total - activas

    puts '=== Personas autorizadas sin usuario ==='
    puts "Total:    #{total}"
    puts "Activas:  #{activas}"
    puts "Inactivas: #{inactivas}"
  end
end

# frozen_string_literal: true

namespace :auditoria do
  desc 'Verifica que la tabla audit_events exista y registra un evento de prueba'
  task test: :environment do
    unless ActiveRecord::Base.connection.data_source_exists?('audit_events')
      abort <<~MSG
        La tabla audit_events no existe.
        Ejecute primero: apps/db/manual/audit_events.sql (ver apps/db/README.md)
      MSG
    end

    evento = Auditoria::Registrar.call(
      accion: 'auditoria.test',
      categoria: Auditoria::Acciones::CATEGORIA_AUTH,
      metadata: { origen: 'rake auditoria:test' },
      mensaje: 'Evento de prueba'
    )

    if evento
      puts "OK: audit_events ##{evento.id} creado (#{evento.accion})"
    else
      abort 'ERROR: no se pudo crear el evento de prueba (revise logs)'
    end
  end
end

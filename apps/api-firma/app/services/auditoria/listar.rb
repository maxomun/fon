# frozen_string_literal: true

module Auditoria
  class Listar
    PER_PAGE_DEFAULT = 25
    PER_PAGE_MAX = 100

    def self.call(scope:, filtros: {}, page: 1, per_page: PER_PAGE_DEFAULT)
      new(scope: scope, filtros: filtros, page: page, per_page: per_page).call
    end

    def self.filtros_desde_params(params, incluir_empresa_id: true)
      filtros = {
        q: params[:q]&.strip,
        categoria: params[:categoria]&.strip,
        accion: params[:accion]&.strip,
        actor_user_id: params[:actor_user_id],
        recurso_tipo: params[:recurso_tipo]&.strip,
        recurso_id: params[:recurso_id]&.strip,
        resultado: params[:resultado]&.strip,
        desde: params[:desde]&.strip,
        hasta: params[:hasta]&.strip
      }

      filtros[:empresa_id] = params[:empresa_id] if incluir_empresa_id

      filtros.compact_blank
    end

    def initialize(scope:, filtros: {}, page: 1, per_page: PER_PAGE_DEFAULT)
      @scope = scope
      @filtros = filtros
      @page = [page.to_i, 1].max
      @per_page = normalizar_per_page(per_page)
    end

    def call
      relation = aplicar_filtros(@scope.recientes.includes(:empresa))
      total_count = relation.count
      eventos = relation.offset((@page - 1) * @per_page).limit(@per_page)

      {
        eventos: eventos,
        meta: {
          current_page: @page,
          total_pages: total_paginas(total_count),
          total_count: total_count,
          per_page: @per_page
        }
      }
    end

    private

    def normalizar_per_page(per_page)
      valor = per_page.to_i
      valor = PER_PAGE_DEFAULT if valor <= 0

      [valor, PER_PAGE_MAX].min
    end

    def total_paginas(total_count)
      return 0 if total_count.zero?

      (total_count.to_f / @per_page).ceil
    end

    def aplicar_filtros(relation)
      relation = relation.where(categoria: @filtros[:categoria]) if @filtros[:categoria].present?
      relation = relation.where(accion: @filtros[:accion]) if @filtros[:accion].present?
      relation = relation.where(empresa_id: @filtros[:empresa_id]) if @filtros[:empresa_id].present?
      relation = relation.where(actor_user_id: @filtros[:actor_user_id]) if @filtros[:actor_user_id].present?
      relation = relation.where(recurso_tipo: @filtros[:recurso_tipo]) if @filtros[:recurso_tipo].present?
      relation = relation.where(recurso_id: @filtros[:recurso_id]) if @filtros[:recurso_id].present?
      relation = relation.where(resultado: normalizar_resultado(@filtros[:resultado])) if @filtros[:resultado].present?
      relation = filtrar_por_fechas(relation)
      filtrar_por_busqueda(relation)
    end

    def normalizar_resultado(resultado)
      case resultado.to_s
      when AuditEvent::RESULTADO_FALLO, 'fallo', 'failure', 'false'
        AuditEvent::RESULTADO_FALLO
      else
        AuditEvent::RESULTADO_EXITO
      end
    end

    def filtrar_por_fechas(relation)
      if (desde = parse_fecha(@filtros[:desde]))
        relation = relation.where('audit_events.created_at >= ?', desde.beginning_of_day)
      end

      if (hasta = parse_fecha(@filtros[:hasta]))
        relation = relation.where('audit_events.created_at <= ?', hasta.end_of_day)
      end

      relation
    end

    def parse_fecha(fecha)
      Time.zone.parse(fecha)
    rescue ArgumentError, TypeError
      nil
    end

    def filtrar_por_busqueda(relation)
      return relation unless @filtros[:q].present?

      termino = "%#{ActiveRecord::Base.sanitize_sql_like(@filtros[:q])}%"
      relation.where(
        <<~SQL.squish,
          audit_events.accion ILIKE :q
          OR audit_events.actor_email ILIKE :q
          OR audit_events.actor_nombre ILIKE :q
          OR audit_events.recurso_label ILIKE :q
          OR audit_events.mensaje ILIKE :q
        SQL
        q: termino
      )
    end
  end
end

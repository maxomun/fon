# frozen_string_literal: true

module AuditoriaQueryable
  extend ActiveSupport::Concern

  private

  def listar_eventos_auditoria(scope)
    paginacion = pagination_params
    resultado = Auditoria::Listar.call(
      scope: scope,
      filtros: filtros_auditoria,
      page: paginacion[:page],
      per_page: paginacion[:per_page]
    )

    render_success(
      data: Auditoria::Payload.collection(resultado[:eventos]),
      meta: resultado[:meta]
    )
  end

  def filtros_auditoria
    Auditoria::Listar.filtros_desde_params(params, incluir_empresa_id: permitir_filtro_empresa_id?)
  end

  def permitir_filtro_empresa_id?
    true
  end

  def render_evento_auditoria(evento)
    render_success(data: Auditoria::Payload.evento(evento, detalle: true))
  end
end

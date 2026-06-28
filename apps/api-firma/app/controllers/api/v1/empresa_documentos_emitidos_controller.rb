# frozen_string_literal: true

module Api
  module V1
    class EmpresaDocumentosEmitidosController < BaseController
      include DocumentoEmitidoSerializable

      PER_PAGE_DEFAULT = 25
      PER_PAGE_MAX = 100

      before_action :set_empresa
      before_action :require_empresa_vinculada!
      before_action :set_documento, only: [:show]

      def index
        scope = documentos_scope
        total_count = scope.count
        documentos = scope.offset((page - 1) * per_page).limit(per_page)

        render_success(
          data: documentos.map { |documento| documento_emitido_list_payload(documento) },
          meta: paginacion_meta(total_count)
        )
      end

      def show
        render_success(data: documento_emitido_detail_payload(@documento))
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_documento
        @documento = @empresa.documento_emitidos
                             .dte
                             .includes(:usuario, :dte_envio, :documento_descuentos_recargos_globales,
                                       tipo_habilitado: :tipo_documento, venta_detalles: :producto)
                             .find(params[:id])
      end

      def require_empresa_vinculada!
        authorize_empresa!(params[:empresa_id])
      end

      def documentos_scope
        scope = @empresa.documento_emitidos
                        .dte
                        .left_joins(:dte_envio)
                        .includes(:usuario, :dte_envio, tipo_habilitado: :tipo_documento)
                        .order(Arel.sql('dte_envios.created_at DESC NULLS LAST'), 'documento_emitidos.id DESC')

        if params[:q].present?
          termino = "%#{params[:q].to_s.strip}%"
          scope = scope.where(
            'documento_emitidos.rut_receptor ILIKE :q OR documento_emitidos.razon_social_receptor ILIKE :q OR CAST(documento_emitidos.folio AS TEXT) LIKE :q',
            q: termino
          )
        end

        if params[:tipo_documento].present?
          scope = scope.joins(tipo_habilitado: :tipo_documento)
                       .where(tipo_documentos: { codigo: params[:tipo_documento] })
        end

        scope
      end

      def page
        [params[:page].to_i, 1].max
      end

      def per_page
        valor = params[:per_page].to_i
        valor = PER_PAGE_DEFAULT if valor <= 0

        [valor, PER_PAGE_MAX].min
      end

      def paginacion_meta(total_count)
        total_pages = total_count.zero? ? 0 : (total_count.to_f / per_page).ceil

        {
          current_page: page,
          total_pages: total_pages,
          total_count: total_count,
          per_page: per_page
        }
      end
    end
  end
end

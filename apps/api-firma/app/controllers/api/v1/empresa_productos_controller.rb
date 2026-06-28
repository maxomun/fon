# frozen_string_literal: true

module Api
  module V1
    class EmpresaProductosController < BaseController
      include ProductoSerializable
      include ProductoAuditable
      include EmpresaAuthorizable

      PER_PAGE_DEFAULT = 25
      PER_PAGE_MAX = 100

      before_action :set_empresa
      before_action :require_empresa_vinculada!, only: [:index, :show, :impuestos_disponibles]
      before_action :require_admin_empresa!, only: [:create, :update, :destroy]
      before_action :set_producto, only: [:show, :update, :destroy]

      # GET /api/v1/empresas/:empresa_id/productos
      def index
        productos = productos_scope
        total_count = productos.count
        paginados = productos.offset((page - 1) * per_page).limit(per_page)

        render_success(
          data: paginados.map { |producto| producto_payload(producto) },
          meta: paginacion_meta(total_count)
        )
      end

      # GET /api/v1/empresas/:empresa_id/productos/:id
      def show
        render_success(data: producto_payload(@producto, detalle: true))
      end

      # GET /api/v1/empresas/:empresa_id/productos/impuestos_disponibles
      def impuestos_disponibles
        impuestos = Impuesto.por_pais(@empresa.pais_id).includes(:impuesto_valores)

        render_success(
          data: impuestos.map { |impuesto| impuesto_disponible_payload(impuesto) }
        )
      end

      # POST /api/v1/empresas/:empresa_id/productos
      def create
        producto = @empresa.productos.build(producto_params)

        if guardar_producto(producto)
          producto.reload
          auditar_evento_producto(
            accion: Auditoria::Acciones::PRODUCTO_CREAR,
            recurso: producto,
            empresa: @empresa,
            metadata: metadata_producto(producto)
          )
          render_success(
            data: producto_payload(producto),
            status: :created,
            message: 'Producto creado exitosamente'
          )
        else
          auditar_evento_producto_fallo(
            accion: Auditoria::Acciones::PRODUCTO_CREAR,
            recurso: producto,
            empresa: @empresa,
            mensaje: producto.errors.full_messages.join(', '),
            metadata: metadata_producto(producto)
          )
          render_producto_validation_error(producto, message: 'Error al crear producto')
        end
      end

      # PATCH/PUT /api/v1/empresas/:empresa_id/productos/:id
      def update
        if guardar_producto(@producto)
          @producto.reload
          auditar_evento_producto(
            accion: Auditoria::Acciones::PRODUCTO_ACTUALIZAR,
            recurso: @producto,
            empresa: @empresa,
            cambios: cambios_producto(@producto, impuestos_extra: @cambios_impuestos_producto),
            metadata: metadata_producto(@producto)
          )
          render_success(
            data: producto_payload(@producto),
            message: 'Producto actualizado exitosamente'
          )
        else
          auditar_evento_producto_fallo(
            accion: Auditoria::Acciones::PRODUCTO_ACTUALIZAR,
            recurso: @producto,
            empresa: @empresa,
            mensaje: @producto.errors.full_messages.join(', '),
            metadata: metadata_producto(@producto)
          )
          render_producto_validation_error(@producto, message: 'Error al actualizar producto')
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/productos/:id
      def destroy
        if @producto.tiene_ventas?
          auditar_evento_producto_fallo(
            accion: Auditoria::Acciones::PRODUCTO_ELIMINAR,
            recurso: @producto,
            empresa: @empresa,
            mensaje: 'Producto con documentos emitidos asociados',
            metadata: metadata_producto(@producto),
            codigo_error: 'PRODUCTO_CON_VENTAS'
          )
          return render_error(
            'No se puede eliminar el producto porque tiene documentos emitidos asociados. Desactívelo en su lugar.',
            :unprocessable_entity,
            code: 'PRODUCTO_CON_VENTAS'
          )
        end

        metadata = metadata_producto(@producto)
        etiqueta = etiqueta_producto(@producto)
        producto_id = @producto.id

        @producto.destroy!

        auditar_evento_producto(
          accion: Auditoria::Acciones::PRODUCTO_ELIMINAR,
          recurso: { tipo: 'Producto', id: producto_id.to_s, label: etiqueta },
          empresa: @empresa,
          metadata: metadata
        )

        render_success(message: 'Producto eliminado exitosamente')
      rescue ActiveRecord::DeleteRestrictionError => e
        auditar_evento_producto_fallo(
          accion: Auditoria::Acciones::PRODUCTO_ELIMINAR,
          recurso: @producto,
          empresa: @empresa,
          mensaje: e.message,
          metadata: metadata_producto(@producto),
          codigo_error: 'DELETE_RESTRICTED'
        )
        render_error(
          'No se puede eliminar el producto porque tiene registros asociados',
          :unprocessable_entity,
          code: 'DELETE_RESTRICTED'
        )
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_producto
        @producto = @empresa.productos
                             .includes(:impuestos, :producto_impuestos)
                             .find(params[:id])
      end

      def productos_scope
        scope = @empresa.productos.includes(:impuestos, :producto_impuestos).order(:codigo)

        if params[:activo].present?
          activo = ActiveModel::Type::Boolean.new.cast(params[:activo])
          scope = scope.where(activo: activo)
        end

        if params[:q].present?
          termino = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
          scope = scope.where('codigo ILIKE :q OR nombre ILIKE :q', q: termino)
        end

        scope
      end

      def guardar_producto(producto)
        @cambios_impuestos_producto = nil
        impuestos_antes = producto.persisted? ? producto.impuesto_ids.sort : nil
        sincronizar_impuestos = sincronizar_impuestos_en_request?(producto)

        ActiveRecord::Base.transaction do
          producto.assign_attributes(producto_params)
          producto.save!

          if sincronizar_impuestos
            resultado = Productos::SincronizarImpuestos.call(
              producto: producto,
              impuesto_ids: producto_impuesto_ids_param,
              pais_id: @empresa.pais_id
            )

            unless resultado.success?
              producto.errors.add(:base, resultado.error)
              raise ActiveRecord::Rollback
            end
          end
        end

        if producto.errors.empty? && impuestos_antes && sincronizar_impuestos
          impuestos_despues = producto.reload.impuesto_ids.sort
          if impuestos_antes != impuestos_despues
            @cambios_impuestos_producto = { 'impuesto_ids' => [impuestos_antes, impuestos_despues] }
          end
        end

        producto.errors.empty?
      rescue ActiveRecord::RecordInvalid
        false
      end

      def sincronizar_impuestos_en_request?(producto)
        producto.new_record? || params[:producto].key?(:impuesto_ids) || params[:producto].key?('impuesto_ids')
      end

      def require_empresa_vinculada!
        authorize_empresa!(params[:empresa_id])
      end

      def producto_params
        params.require(:producto).permit(:codigo, :nombre, :precio_unitario, :activo, :ambito_monto)
      end

      def producto_impuesto_ids_param
        return [] unless params[:producto].key?(:impuesto_ids) || params[:producto].key?('impuesto_ids')

        Array(params[:producto][:impuesto_ids] || params[:producto]['impuesto_ids'])
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

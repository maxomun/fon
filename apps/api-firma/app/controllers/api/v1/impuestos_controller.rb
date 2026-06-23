# frozen_string_literal: true

module Api
  module V1
    class ImpuestosController < BaseController
      include ImpuestoSerializable
      include EmpresaConfigAuditable

      before_action :require_administrador_fon!
      before_action :set_impuesto, only: [:show, :update, :destroy]

      # GET /api/v1/impuestos?pais_id=
      def index
        return render_pais_id_required unless params[:pais_id].present?

        impuestos = Impuesto.por_pais(params[:pais_id]).includes(:pais, :impuesto_valores)
        render_success(data: impuestos.map { |impuesto| impuesto_payload(impuesto) })
      end

      # GET /api/v1/impuestos/:id
      def show
        render_success(data: impuesto_payload(@impuesto, include_valores: true))
      end

      # POST /api/v1/impuestos
      def create
        impuesto = Impuesto.new(impuesto_create_params)

        if impuesto.save
          impuesto = Impuesto.includes(:pais, :impuesto_valores).find(impuesto.id)
          auditar_evento_catalogo(
            accion: Auditoria::Acciones::IMPUESTO_CREAR,
            recurso: impuesto,
            metadata: { pais_id: impuesto.pais_id, abreviacion: impuesto.abreviacion }
          )
          render_success(
            data: impuesto_payload(impuesto),
            status: :created,
            message: 'Impuesto creado exitosamente'
          )
        else
          auditar_evento_catalogo_fallo(
            accion: Auditoria::Acciones::IMPUESTO_CREAR,
            recurso: impuesto,
            mensaje: impuesto.errors.full_messages.join(', ')
          )
          render_impuesto_validation_error(impuesto)
        end
      end

      # PATCH/PUT /api/v1/impuestos/:id
      def update
        if @impuesto.update(impuesto_update_params)
          auditar_evento_catalogo(
            accion: Auditoria::Acciones::IMPUESTO_ACTUALIZAR,
            recurso: @impuesto,
            cambios: Auditoria::Cambios.desde_modelo(@impuesto),
            metadata: { abreviacion: @impuesto.abreviacion }
          )
          render_success(
            data: impuesto_payload(@impuesto),
            message: 'Impuesto actualizado exitosamente'
          )
        else
          auditar_evento_catalogo_fallo(
            accion: Auditoria::Acciones::IMPUESTO_ACTUALIZAR,
            recurso: @impuesto,
            mensaje: @impuesto.errors.full_messages.join(', ')
          )
          render_impuesto_validation_error(@impuesto)
        end
      end

      # DELETE /api/v1/impuestos/:id
      def destroy
        if @impuesto.tiene_productos?
          auditar_evento_catalogo_fallo(
            accion: Auditoria::Acciones::IMPUESTO_ELIMINAR,
            recurso: @impuesto,
            mensaje: 'Tiene productos asignados'
          )
          return render_error(
            'No se puede eliminar el impuesto porque está asignado a productos',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED'
          )
        end

        metadata = {
          abreviacion: @impuesto.abreviacion,
          pais_id: @impuesto.pais_id
        }

        if @impuesto.destroy
          auditar_evento_catalogo(
            accion: Auditoria::Acciones::IMPUESTO_ELIMINAR,
            recurso: { tipo: 'Impuesto', id: params[:id], label: metadata[:abreviacion] },
            metadata: metadata
          )
          render_success(message: 'Impuesto eliminado exitosamente')
        else
          auditar_evento_catalogo_fallo(
            accion: Auditoria::Acciones::IMPUESTO_ELIMINAR,
            recurso: @impuesto,
            mensaje: @impuesto.errors.full_messages.join(', ')
          )
          render_error(
            'No se pudo eliminar el impuesto',
            :unprocessable_entity,
            code: 'DELETE_FAILED',
            errors: @impuesto.errors.full_messages
          )
        end
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def set_impuesto
        @impuesto = Impuesto.includes(:pais, :impuesto_valores).find(params[:id])
      end

      def impuesto_create_params
        params.require(:impuesto).permit(:pais_id, :nombre, :abreviacion)
      end

      def impuesto_update_params
        params.require(:impuesto).permit(:nombre, :abreviacion)
      end

      def render_pais_id_required
        render_error(
          'El parámetro pais_id es obligatorio',
          :bad_request,
          code: 'PAIS_ID_REQUIRED'
        )
      end
    end
  end
end

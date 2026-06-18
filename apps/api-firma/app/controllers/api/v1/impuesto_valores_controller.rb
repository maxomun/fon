# frozen_string_literal: true

module Api
  module V1
    class ImpuestoValoresController < BaseController
      include ImpuestoSerializable

      before_action :require_administrador_fon!
      before_action :set_impuesto
      before_action :set_impuesto_valor, only: [:update, :destroy]

      # GET /api/v1/impuestos/:impuesto_id/valores
      def index
        valores = @impuesto.impuesto_valores.ordenados
        render_success(data: valores.map { |valor| impuesto_valor_payload(valor) })
      end

      # POST /api/v1/impuestos/:impuesto_id/valores
      def create
        resultado = Impuestos::RegistrarValor.call(
          impuesto: @impuesto,
          attributes: impuesto_valor_params.to_h
        )

        if resultado.success?
          render_success(
            data: impuesto_valor_payload(resultado.impuesto_valor),
            status: :created,
            message: 'Valor de impuesto registrado exitosamente'
          )
        else
          render_error(
            'Error de validación',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      # PATCH/PUT /api/v1/impuestos/:impuesto_id/valores/:id
      def update
        if @impuesto_valor.update(impuesto_valor_params)
          render_success(
            data: impuesto_valor_payload(@impuesto_valor),
            message: 'Valor de impuesto actualizado exitosamente'
          )
        else
          render_impuesto_validation_error(@impuesto_valor)
        end
      end

      # DELETE /api/v1/impuestos/:impuesto_id/valores/:id
      def destroy
        if @impuesto_valor.destroy
          render_success(message: 'Valor de impuesto eliminado exitosamente')
        else
          render_error(
            'No se pudo eliminar el valor de impuesto',
            :unprocessable_entity,
            code: 'DELETE_FAILED',
            errors: @impuesto_valor.errors.full_messages
          )
        end
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def set_impuesto
        @impuesto = Impuesto.includes(:pais).find(params[:impuesto_id])
      end

      def set_impuesto_valor
        @impuesto_valor = @impuesto.impuesto_valores.find(params[:id])
      end

      def impuesto_valor_params
        permitted = params.require(:impuesto_valor).permit(:valor, :fecha_activacion, :fecha_caducacion)
        permitted[:fecha_caducacion] = nil if permitted.key?(:fecha_caducacion) && permitted[:fecha_caducacion].blank?
        permitted
      end
    end
  end
end

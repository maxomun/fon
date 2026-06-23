# frozen_string_literal: true

module Api
  module V1
    class EmpresaActecosController < BaseController
      include ActecoSerializable
      include EmpresaAuthorizable
      include EmpresaConfigAuditable

      before_action :require_admin_empresa!
      before_action :set_empresa

      # GET /api/v1/empresas/:empresa_id/actecos
      def index
        actecos = @empresa.actecos.includes(:grupo_acteco).order(:codigo)
        render_success(data: actecos.map { |acteco| acteco_payload(acteco) })
      end

      # POST /api/v1/empresas/:empresa_id/actecos
      def create
        acteco = Acteco.find(acteco_params[:acteco_id])
        assignment = @empresa.acteco_empresas.build(acteco: acteco)

        if assignment.save
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_ACTECO_ASIGNAR,
            recurso: acteco,
            empresa: @empresa,
            metadata: { acteco_id: acteco.id, codigo: acteco.codigo, nombre: acteco.nombre }
          )
          render_success(
            data: acteco_payload(acteco),
            status: :created,
            message: 'Actividad económica asignada exitosamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_ACTECO_ASIGNAR,
            recurso: acteco,
            empresa: @empresa,
            mensaje: assignment.errors.full_messages.join(', '),
            metadata: { acteco_id: acteco.id }
          )
          render_validation_error(assignment)
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/actecos/:id
      def destroy
        acteco = Acteco.find(params[:id])
        assignment = @empresa.acteco_empresas.find_by!(acteco_id: params[:id])
        assignment.destroy!

        auditar_evento_empresa(
          accion: Auditoria::Acciones::EMPRESA_ACTECO_QUITAR,
          recurso: acteco,
          empresa: @empresa,
          metadata: { acteco_id: acteco.id, codigo: acteco.codigo, nombre: acteco.nombre }
        )

        render_success(message: 'Actividad económica quitada exitosamente')
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def acteco_params
        params.require(:acteco).permit(:acteco_id)
      end

      def render_validation_error(record)
        render_error(
          'Error de validación',
          :unprocessable_entity,
          code: 'VALIDATION_ERROR',
          errors: record.errors.full_messages
        )
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class EmpresasController < BaseController
      before_action :require_administrador_fon!
      before_action :set_empresa, only: [:show, :update, :destroy]

      # GET /api/v1/empresas
      def index
        empresas = Empresa.includes(:pais).order(:razon_social)
        render_success(data: empresas.map { |empresa| empresa_payload(empresa) })
      end

      # GET /api/v1/empresas/:id
      def show
        render_success(data: empresa_payload(@empresa))
      end

      # POST /api/v1/empresas
      def create
        empresa = Empresa.new(empresa_params)

        if empresa.save
          render_success(
            data: empresa_payload(Empresa.includes(:pais).find(empresa.id)),
            status: :created,
            message: 'Empresa creada exitosamente'
          )
        else
          render_validation_error(empresa)
        end
      end

      # PATCH/PUT /api/v1/empresas/:id
      def update
        if @empresa.update(empresa_params)
          render_success(
            data: empresa_payload(@empresa),
            message: 'Empresa actualizada exitosamente'
          )
        else
          render_validation_error(@empresa)
        end
      end

      # DELETE /api/v1/empresas/:id
      def destroy
        if @empresa.destroy
          render_success(message: 'Empresa eliminada exitosamente')
        else
          render_error(
            'No se puede eliminar la empresa porque tiene registros asociados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED',
            errors: @empresa.errors.full_messages
          )
        end
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def set_empresa
        @empresa = Empresa.includes(:pais).find(params[:id])
      end

      def empresa_params
        params.require(:empresa).permit(
          :pais_id,
          :rut,
          :razon_social,
          :nombre_fantasia,
          :giro,
          :direccion,
          :resolucion_timbre,
          :fecha_resolucion,
          :numero_resolucion,
          :telefono1,
          :telefono2,
          :archivo_logo
        )
      end

      def empresa_payload(empresa)
        {
          id: empresa.id,
          pais_id: empresa.pais_id,
          pais: {
            id: empresa.pais.id,
            codigo: empresa.pais.codigo,
            nombre: empresa.pais.nombre
          },
          rut: empresa.rut,
          razon_social: empresa.razon_social,
          nombre_fantasia: empresa.nombre_fantasia,
          giro: empresa.giro,
          direccion: empresa.direccion,
          resolucion_timbre: empresa.resolucion_timbre,
          fecha_resolucion: empresa.fecha_resolucion,
          numero_resolucion: empresa.numero_resolucion,
          telefono1: empresa.telefono1,
          telefono2: empresa.telefono2,
          archivo_logo: empresa.archivo_logo,
          fecha_creacion: empresa.fecha_creacion,
          fecha_actualizacion: empresa.fecha_actualizacion
        }.merge(empresa.certificado_estado_payload)
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

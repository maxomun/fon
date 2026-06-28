# frozen_string_literal: true

module Api
  module V1
    class EmpresasController < BaseController
      include EmpresaAuthorizable
      include EmpresaConfigAuditable
      include EmpresaLogoSerializable

      before_action :require_empresas_visibility!, only: [:index]
      before_action :authorize_empresa_show!, only: [:show]
      before_action :require_administrador_fon!, only: [:create, :update, :destroy]
      before_action :set_empresa, only: [:show, :update, :destroy]

      # GET /api/v1/empresas
      def index
        empresas = empresas_visibles.includes(:pais).order(:razon_social)
        render_success(
          data: empresas.map { |empresa| empresa_payload(empresa, es_administrador: es_administrador_de?(empresa)) }
        )
      end

      # GET /api/v1/empresas/:id
      def show
        render_success(
          data: empresa_payload(@empresa, es_administrador: es_administrador_de?(@empresa))
        )
      end

      # POST /api/v1/empresas
      def create
        empresa = Empresa.new(empresa_params)

        if empresa.save
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_CREAR,
            recurso: empresa,
            empresa: empresa,
            metadata: { rut: empresa.rut, razon_social: empresa.razon_social }
          )
          render_success(
            data: empresa_payload(Empresa.includes(:pais).find(empresa.id), es_administrador: true),
            status: :created,
            message: 'Empresa creada exitosamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_CREAR,
            recurso: empresa,
            empresa: nil,
            mensaje: empresa.errors.full_messages.join(', '),
            metadata: { rut: empresa.rut }
          )
          render_validation_error(empresa)
        end
      end

      # PATCH/PUT /api/v1/empresas/:id
      def update
        if @empresa.update(empresa_params)
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_ACTUALIZAR,
            recurso: @empresa,
            empresa: @empresa,
            cambios: Auditoria::Cambios.desde_modelo(@empresa)
          )
          render_success(
            data: empresa_payload(@empresa, es_administrador: es_administrador_de?(@empresa)),
            message: 'Empresa actualizada exitosamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_ACTUALIZAR,
            recurso: @empresa,
            empresa: @empresa,
            mensaje: @empresa.errors.full_messages.join(', ')
          )
          render_validation_error(@empresa)
        end
      end

      # DELETE /api/v1/empresas/:id
      def destroy
        snapshot = {
          rut: @empresa.rut,
          razon_social: @empresa.razon_social
        }

        if @empresa.destroy
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_ELIMINAR,
            recurso: { tipo: 'Empresa', id: params[:id], label: snapshot[:razon_social] },
            empresa: nil,
            metadata: snapshot
          )
          render_success(message: 'Empresa eliminada exitosamente')
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_ELIMINAR,
            recurso: @empresa,
            empresa: @empresa,
            mensaje: @empresa.errors.full_messages.join(', ')
          )
          render_error(
            'No se puede eliminar la empresa porque tiene registros asociados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED',
            errors: @empresa.errors.full_messages
          )
        end
      end

      private

      def empresas_visibles
        if current_user.administrador_fon?
          Empresa.all
        else
          current_user.empresas_como_administrador
        end
      end

      def es_administrador_de?(empresa)
        current_user.administrador_en_empresa?(empresa.id)
      end

      def set_empresa
        @empresa = empresas_visibles.includes(:pais).find(params[:id])
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

      def empresa_payload(empresa, es_administrador: false)
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
          logo: logo_payload(empresa),
          fecha_creacion: empresa.fecha_creacion,
          fecha_actualizacion: empresa.fecha_actualizacion,
          es_administrador: es_administrador
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

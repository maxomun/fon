# frozen_string_literal: true

module Api
  module V1
    class EmpresaTiposHabilitadosController < BaseController
      include TipoHabilitadoSerializable
      include EmpresaAuthorizable
      include EmpresaConfigAuditable

      before_action :require_admin_empresa!
      before_action :set_empresa
      before_action :set_tipo_habilitado, only: [:update, :destroy]

      # GET /api/v1/empresas/:empresa_id/tipos_habilitados
      def index
        tipos = @empresa.tipo_habilitados
                        .includes(:tipo_documento)
                        .joins(:tipo_documento)
                        .order('tipo_documentos.codigo ASC')

        render_success(data: tipos.map { |tipo| tipo_habilitado_payload(tipo) })
      end

      # POST /api/v1/empresas/:empresa_id/tipos_habilitados
      def create
        tipo_habilitado = @empresa.tipo_habilitados.build(tipo_habilitado_create_params)

        if tipo_habilitado.save
          tipo = TipoHabilitado.includes(:tipo_documento).find(tipo_habilitado.id)
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_HABILITAR,
            recurso: tipo,
            empresa: @empresa,
            metadata: metadata_tipo_habilitado(tipo)
          )
          render_success(
            data: tipo_habilitado_payload(tipo),
            status: :created,
            message: 'Tipo de documento habilitado exitosamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_HABILITAR,
            recurso: tipo_habilitado,
            empresa: @empresa,
            mensaje: tipo_habilitado.errors.full_messages.join(', ')
          )
          render_tipo_habilitado_validation_error(tipo_habilitado)
        end
      end

      # PATCH/PUT /api/v1/empresas/:empresa_id/tipos_habilitados/:id
      def update
        if @tipo_habilitado.update(tipo_habilitado_update_params)
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_ACTUALIZAR,
            recurso: @tipo_habilitado,
            empresa: @empresa,
            cambios: Auditoria::Cambios.desde_modelo(@tipo_habilitado),
            metadata: metadata_tipo_habilitado(@tipo_habilitado)
          )
          render_success(
            data: tipo_habilitado_payload(@tipo_habilitado),
            message: 'Habilitación actualizada exitosamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_ACTUALIZAR,
            recurso: @tipo_habilitado,
            empresa: @empresa,
            mensaje: @tipo_habilitado.errors.full_messages.join(', ')
          )
          render_tipo_habilitado_validation_error(@tipo_habilitado)
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/tipos_habilitados/:id
      def destroy
        if @tipo_habilitado.tiene_rangos_folio?
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_DESHABILITAR,
            recurso: @tipo_habilitado,
            empresa: @empresa,
            mensaje: 'Tiene rangos de folios (CAF) cargados',
            metadata: metadata_tipo_habilitado(@tipo_habilitado)
          )
          return render_error(
            'No se puede quitar la habilitación porque tiene rangos de folios (CAF) cargados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED'
          )
        end

        if @tipo_habilitado.tiene_documentos_emitidos?
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_DESHABILITAR,
            recurso: @tipo_habilitado,
            empresa: @empresa,
            mensaje: 'Tiene documentos emitidos',
            metadata: metadata_tipo_habilitado(@tipo_habilitado)
          )
          return render_error(
            'No se puede quitar la habilitación porque tiene documentos emitidos',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED'
          )
        end

        metadata = metadata_tipo_habilitado(@tipo_habilitado)

        if @tipo_habilitado.destroy
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_DESHABILITAR,
            recurso: { tipo: 'TipoHabilitado', id: params[:id], label: metadata[:tipo_documento_nombre] },
            empresa: @empresa,
            metadata: metadata
          )
          render_success(message: 'Tipo de documento quitado exitosamente')
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_TIPO_DOCUMENTO_DESHABILITAR,
            recurso: @tipo_habilitado,
            empresa: @empresa,
            mensaje: @tipo_habilitado.errors.full_messages.join(', ')
          )
          render_error(
            'No se pudo quitar la habilitación',
            :unprocessable_entity,
            code: 'DELETE_FAILED',
            errors: @tipo_habilitado.errors.full_messages
          )
        end
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_tipo_habilitado
        @tipo_habilitado = @empresa.tipo_habilitados
                                    .includes(:tipo_documento)
                                    .find(params[:id])
      end

      def tipo_habilitado_create_params
        permitted = params.require(:tipo_habilitado).permit(:tipo_documento_id, :fecha_habilitacion)
        permitted[:fecha_habilitacion] = Time.current if permitted[:fecha_habilitacion].blank?
        permitted
      end

      def tipo_habilitado_update_params
        params.require(:tipo_habilitado).permit(:fecha_habilitacion)
      end

      def metadata_tipo_habilitado(tipo_habilitado)
        {
          tipo_documento_id: tipo_habilitado.tipo_documento_id,
          tipo_documento_codigo: tipo_habilitado.tipo_documento&.codigo,
          tipo_documento_nombre: tipo_habilitado.tipo_documento&.nombre
        }
      end
    end
  end
end

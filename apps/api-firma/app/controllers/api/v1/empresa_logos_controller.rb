# frozen_string_literal: true

module Api
  module V1
    class EmpresaLogosController < BaseController
      include EmpresaAuthorizable
      include EmpresaConfigAuditable
      include EmpresaLogoSerializable

      before_action :set_empresa
      before_action :authorize_logo_access!, only: [:show]
      before_action :require_administrador_fon!, only: [:create, :destroy]

      # GET /api/v1/empresas/:empresa_id/logo
      def show
        unless @empresa.logo.attached?
          return render_error('La empresa no tiene logo', :not_found, code: 'LOGO_NOT_FOUND')
        end

        blob = @empresa.logo.blob
        send_data blob.download,
                  type: blob.content_type,
                  disposition: 'inline',
                  filename: blob.filename.to_s
      end

      # POST /api/v1/empresas/:empresa_id/logo
      # Form-data: archivo (PNG, JPEG o WebP)
      def create
        unless params[:archivo].present?
          return render_error(
            'Debe adjuntar un archivo de logo',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR'
          )
        end

        resultado = Empresas::ProcesadorLogo.call(empresa: @empresa, archivo: params[:archivo])

        if resultado.success?
          auditar_evento_empresa(
            accion: Auditoria::Acciones::EMPRESA_LOGO_SUBIR,
            recurso: @empresa,
            empresa: @empresa,
            metadata: resultado.metadata
          )
          render_success(
            data: logo_payload(@empresa.reload),
            status: :created,
            message: 'Logo cargado correctamente'
          )
        else
          auditar_evento_empresa_fallo(
            accion: Auditoria::Acciones::EMPRESA_LOGO_SUBIR,
            recurso: @empresa,
            empresa: @empresa,
            mensaje: resultado.errors.join('. '),
            metadata: { filename: params[:archivo]&.original_filename }
          )
          render_error(
            resultado.errors.join('. '),
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/logo
      def destroy
        unless @empresa.logo.attached?
          return render_error('La empresa no tiene logo', :not_found, code: 'LOGO_NOT_FOUND')
        end

        metadata = logo_payload(@empresa)
        ActiveStorage::EliminadorSinPurge.call(record: @empresa, name: :logo)
        @empresa.update!(archivo_logo: nil)

        auditar_evento_empresa(
          accion: Auditoria::Acciones::EMPRESA_LOGO_ELIMINAR,
          recurso: @empresa,
          empresa: @empresa,
          metadata: metadata
        )
        render_success(
          data: logo_payload(@empresa.reload),
          message: 'Logo eliminado correctamente'
        )
      end

      private

      def set_empresa
        scope = if current_user.administrador_fon?
                  Empresa.all
                else
                  current_user.empresas_como_administrador
                end
        @empresa = scope.find(params[:empresa_id])
      end

      def authorize_logo_access!
        return if current_user.administrador_fon?

        authorize_admin_empresa!(params[:empresa_id])
      end
    end
  end
end

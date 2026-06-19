# frozen_string_literal: true

module Api
  module V1
    # Rutas legacy para compatibilidad. Preferir REST anidado bajo empresas.
    class RangoFoliosController < BaseController
      include RangoFolioSerializable

      before_action :require_administrador_fon!

      # POST /api/v1/rango_folios/cargar
      def cargar
        return render_empresa_id_required unless params[:empresa_id].present?

        empresa = Empresa.find_by(id: params[:empresa_id])
        return render_error('Empresa no encontrada', :not_found, code: 'NOT_FOUND') unless empresa

        create_caf_for(empresa)
      end

      # GET /api/v1/rango_folios/listar?empresa_id=
      def listar
        return render_empresa_id_required unless params[:empresa_id].present?

        empresa = Empresa.find_by(id: params[:empresa_id])
        return render_error('Empresa no encontrada', :not_found, code: 'NOT_FOUND') unless empresa

        render_rangos_for(empresa)
      end

      # GET /api/v1/rango_folios/obtener?id=
      def obtener
        return render_error('id es requerido', :bad_request, code: 'BAD_REQUEST') unless params[:id].present?

        rango = RangoFolio.includes(:empresa, :tipo_habilitado, tipo_habilitado: :tipo_documento)
                          .find_by(id: params[:id])
        return render_error('Rango de folio no encontrado', :not_found, code: 'NOT_FOUND') unless rango

        render_success(data: rango_folio_detail_payload(rango))
      end

      # DELETE /api/v1/rango_folios/eliminar?id=
      def eliminar
        return render_error('id es requerido', :bad_request, code: 'BAD_REQUEST') unless params[:id].present?

        rango = RangoFolio.find_by(id: params[:id])
        return render_error('Rango de folio no encontrado', :not_found, code: 'NOT_FOUND') unless rango

        destroy_rango(rango)
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def render_empresa_id_required
        render_error('empresa_id es requerido', :bad_request, code: 'EMPRESA_ID_REQUIRED')
      end

      def create_caf_for(empresa)
        unless params[:archivo].present?
          return render_error(
            'Debe adjuntar un archivo CAF',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR'
          )
        end

        resultado = RangosFolios::ImportarCaf.call(
          empresa: empresa,
          archivo: params[:archivo],
          username: current_user.email
        )

        if resultado.success?
          rango = RangoFolio.includes(:tipo_habilitado, tipo_habilitado: :tipo_documento)
                            .find(resultado.rango_folio.id)
          render_success(
            data: rango_folio_payload(rango),
            status: :created,
            message: 'Archivo CAF cargado correctamente'
          )
        else
          render_error(
            'Error al cargar el archivo CAF',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      def render_rangos_for(empresa)
        rangos = empresa.rango_folios
                        .includes(:tipo_habilitado, tipo_habilitado: :tipo_documento)
                        .order(fecha_subida: :desc)

        render_success(data: rangos.map { |rango| rango_folio_payload(rango) })
      end

      def destroy_rango(rango)
        if rango.folios.usados.exists?
          return render_error(
            'No se puede eliminar un rango que tiene folios usados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED',
            errors: ["Folios usados: #{rango.folios.usados.count}"]
          )
        end

        rango.destroy!
        render_success(message: 'Rango de folio eliminado correctamente')
      rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
        render_error(
          'No se pudo eliminar el rango de folio',
          :unprocessable_entity,
          code: 'DELETE_FAILED'
        )
      end
    end
  end
end

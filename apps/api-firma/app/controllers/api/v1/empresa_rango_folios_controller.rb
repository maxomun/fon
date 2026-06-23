# frozen_string_literal: true

module Api
  module V1
    class EmpresaRangoFoliosController < BaseController
      include RangoFolioSerializable
      include EmpresaAuthorizable
      include EmpresaConfigAuditable

      before_action :require_admin_empresa!
      before_action :set_empresa
      before_action :set_rango_folio, only: [:show, :destroy]

      # GET /api/v1/empresas/:empresa_id/rangos_folios
      def index
        rangos = @empresa.rango_folios
                         .includes(:tipo_habilitado, tipo_habilitado: :tipo_documento)
                         .order(fecha_subida: :desc)

        render_success(data: rangos.map { |rango| rango_folio_payload(rango) })
      end

      # GET /api/v1/empresas/:empresa_id/rangos_folios/:id
      def show
        render_success(data: rango_folio_detail_payload(@rango_folio))
      end

      # POST /api/v1/empresas/:empresa_id/rangos_folios
      # Form-data: archivo (XML CAF)
      def create
        unless params[:archivo].present?
          return render_error(
            'Debe adjuntar un archivo CAF',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR'
          )
        end

        resultado = RangosFolios::ImportarCaf.call(
          empresa: @empresa,
          archivo: params[:archivo],
          username: current_user.email
        )

        if resultado.success?
          rango = RangoFolio.includes(:tipo_habilitado, tipo_habilitado: :tipo_documento)
                            .find(resultado.rango_folio.id)
          auditar_evento_folio(
            accion: Auditoria::Acciones::FOLIO_CAF_CARGAR,
            recurso: rango,
            empresa: @empresa,
            metadata: metadata_rango_folio(rango)
          )
          render_success(
            data: rango_folio_payload(rango),
            status: :created,
            message: 'Archivo CAF cargado correctamente'
          )
        else
          auditar_evento_folio(
            accion: Auditoria::Acciones::FOLIO_CAF_CARGAR,
            recurso: { tipo: 'RangoFolio', label: params[:archivo]&.original_filename },
            empresa: @empresa,
            resultado: AuditEvent::RESULTADO_FALLO,
            mensaje: resultado.errors.presence&.join('. ')
          )
          render_error(
            resultado.errors.presence&.join('. ') || 'Error al cargar el archivo CAF',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/rangos_folios/:id
      def destroy
        if @rango_folio.folios.usados.exists?
          auditar_evento_folio(
            accion: Auditoria::Acciones::FOLIO_CAF_ELIMINAR,
            recurso: @rango_folio,
            empresa: @empresa,
            resultado: AuditEvent::RESULTADO_FALLO,
            mensaje: 'Tiene folios usados',
            metadata: metadata_rango_folio(@rango_folio)
          )
          return render_error(
            'No se puede eliminar un rango que tiene folios usados',
            :unprocessable_entity,
            code: 'DELETE_RESTRICTED',
            errors: ["Folios usados: #{@rango_folio.folios.usados.count}"]
          )
        end

        metadata = metadata_rango_folio(@rango_folio)
        @rango_folio.destroy!

        auditar_evento_folio(
          accion: Auditoria::Acciones::FOLIO_CAF_ELIMINAR,
          recurso: { tipo: 'RangoFolio', id: params[:id], label: "#{metadata[:td]} #{metadata[:desde]}-#{metadata[:hasta]}" },
          empresa: @empresa,
          metadata: metadata
        )

        render_success(message: 'Rango de folio eliminado correctamente')
      rescue ActiveRecord::RecordNotDestroyed, ActiveRecord::InvalidForeignKey
        auditar_evento_folio(
          accion: Auditoria::Acciones::FOLIO_CAF_ELIMINAR,
          recurso: @rango_folio,
          empresa: @empresa,
          resultado: AuditEvent::RESULTADO_FALLO,
          mensaje: 'No se pudo eliminar el rango de folio',
          metadata: metadata_rango_folio(@rango_folio)
        )
        render_error(
          'No se pudo eliminar el rango de folio',
          :unprocessable_entity,
          code: 'DELETE_FAILED'
        )
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_rango_folio
        @rango_folio = @empresa.rango_folios
                               .includes(:empresa, :tipo_habilitado, tipo_habilitado: :tipo_documento)
                               .find(params[:id])
      end

      def metadata_rango_folio(rango)
        {
          td: rango.td,
          desde: rango.d,
          hasta: rango.h,
          archivo: rango.archivo,
          tipo_documento: rango.tipo_habilitado&.tipo_documento&.nombre
        }
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class EmpresaDteEnviosController < BaseController
      include EmpresaAuthorizable
      include DteAuditable

      before_action :set_empresa
      before_action :require_empresa_vinculada!, only: [:xml]
      before_action :require_administrador_fon!, only: [:limpiar, :limpiar_todos]
      before_action :set_dte_envio, only: [:xml, :limpiar]

      def xml
        unless @dte_envio.xml_firmado.attached?
          return render_error('XML no disponible para este envío', :not_found, code: 'XML_NOT_FOUND')
        end

        documentos = @dte_envio.documento_emitidos.includes(tipo_habilitado: :tipo_documento).order(:folio)
        filename = Dte::NombreArchivoEnvio.for_envio(
          dte_envio: @dte_envio,
          empresa: @empresa,
          documentos: documentos
        )

        response.headers['X-Download-Filename'] = filename

        send_data @dte_envio.xml_firmado.download,
                  filename: filename,
                  type: @dte_envio.xml_firmado.content_type || 'application/xml',
                  disposition: 'attachment'
      end

      def limpiar
        dte_envio_id = @dte_envio.id
        resultado = Dte::LimpiadorEnvio.call(dte_envio: @dte_envio)

        unless resultado[:success]
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_LIMPIAR_ENVIO,
            empresa: @empresa,
            mensaje: resultado[:error],
            metadata: { dte_envio_id: dte_envio_id },
            codigo_error: resultado[:code]
          )
          return render_error(resultado[:error], :unprocessable_entity, code: resultado[:code])
        end

        auditar_dte(
          accion: Auditoria::Acciones::DTE_LIMPIAR_ENVIO,
          empresa: @empresa,
          recurso: { tipo: 'DteEnvio', id: dte_envio_id.to_s, label: "Envío DTE ##{dte_envio_id}" },
          metadata: {
            dte_envio_id: dte_envio_id,
            documentos_eliminados: resultado[:documentos_eliminados],
            folios_liberados: resultado[:folios_liberados]
          }
        )

        render_success(
          message: 'Envío eliminado y folios liberados para nuevas pruebas',
          data: resultado
        )
      end

      def limpiar_todos
        resultado = Dte::LimpiadorEnviosEmpresa.call(empresa: @empresa)

        if resultado[:envios_limpiados].zero? && resultado[:errores].any?
          auditar_dte_fallo(
            accion: Auditoria::Acciones::DTE_LIMPIAR_ENVIOS,
            empresa: @empresa,
            mensaje: resultado[:errores].first[:error],
            metadata: { errores: resultado[:errores] },
            codigo_error: resultado[:errores].first[:code]
          )
          return render_error(
            'No se pudo limpiar ningún envío',
            :unprocessable_entity,
            code: 'LIMPIEZA_FALLIDA',
            errors: resultado[:errores].map { |item| item[:error] }
          )
        end

        auditar_dte(
          accion: Auditoria::Acciones::DTE_LIMPIAR_ENVIOS,
          empresa: @empresa,
          recurso_label: "Envíos DTE de #{@empresa.razon_social}",
          metadata: {
            envios_limpiados: resultado[:envios_limpiados],
            documentos_eliminados: resultado[:documentos_eliminados],
            folios_liberados: resultado[:folios_liberados],
            errores: resultado[:errores]
          }
        )

        mensaje = if resultado[:errores].any?
                    "Se limpiaron #{resultado[:envios_limpiados]} envío(s); #{resultado[:errores].count} no pudieron eliminarse"
                  else
                    "Se limpiaron #{resultado[:envios_limpiados]} envío(s) y se liberaron los folios asociados"
                  end

        render_success(message: mensaje, data: resultado)
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_dte_envio
        @dte_envio = @empresa.dte_envios.find(params[:id])
      end

      def require_empresa_vinculada!
        authorize_empresa!(params[:empresa_id])
      end
    end
  end
end

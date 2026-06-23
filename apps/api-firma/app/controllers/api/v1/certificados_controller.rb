# frozen_string_literal: true

module Api
  module V1
    class CertificadosController < BaseController
      include EmpresaConfigAuditable

      before_action :require_administrador_fon!

      # POST /api/v1/certificados/crear
      #
      # Form-data:
      #   persona_autorizada_id: ID de la persona autorizada
      #   empresa_id: (opcional) valida vínculo persona-empresa
      #   archivo_crs: .crt o .pem
      #   archivo_key: .key o .pem
      #   frase_clave: password de la clave privada
      def crear
        persona = nil
        empresa = nil

        return error_parametros('persona_autorizada_id es requerido') unless params[:persona_autorizada_id].present?
        return error_parametros('archivo_crs es requerido') unless params[:archivo_crs].present?
        return error_parametros('archivo_key es requerido') unless params[:archivo_key].present?
        return error_parametros('frase_clave es requerida') unless params[:frase_clave].present?

        persona = PersonaAutorizada.find_by(id: params[:persona_autorizada_id])
        return error_no_encontrado('Persona autorizada no encontrada') unless persona

        empresa = nil
        if params[:empresa_id].present?
          empresa = Empresa.find_by(id: params[:empresa_id])
          return error_no_encontrado('Empresa no encontrada') unless empresa
          return error_validacion('La persona autorizada no está vinculada a esta empresa') unless persona_vinculada_a_empresa?(persona, empresa)
        end

        certificados_reemplazados = persona.certificados.vigentes.pluck(:id)
        certificado = nil

        Certificado.transaction do
          persona.certificados.vigentes.update_all(vigente: false)

          certificado = Certificado.new(
            persona_autorizada: persona,
            fecha_adjuncion: Time.current,
            vigente: true,
            fecha_caducacion: nil,
            frase_clave: params[:frase_clave],
            responsable: persona.nombre_completo.presence || persona.rut
          )

          attach_certificate_files!(certificado)
          certificado.save!

          unless certificado.clave_privada
            certificado.destroy
            raise StandardError, 'No se pudo cargar la clave privada. Verifique la frase clave.'
          end
        end

        auditar_evento_certificado(
          accion: Auditoria::Acciones::CERTIFICADO_CREAR,
          recurso: certificado,
          empresa: empresa,
          metadata: metadata_certificado(certificado, persona)
        )

        if certificados_reemplazados.any?
          auditar_evento_certificado(
            accion: Auditoria::Acciones::CERTIFICADO_REEMPLAZAR,
            recurso: certificado,
            empresa: empresa,
            metadata: metadata_certificado(certificado, persona).merge(
              certificados_anteriores_ids: certificados_reemplazados
            )
          )
        end

        render_success(
          data: certificado_payload(certificado),
          status: :created,
          message: 'Certificado creado exitosamente'
        )
      rescue ActiveRecord::RecordInvalid => e
        auditar_evento_certificado(
          accion: Auditoria::Acciones::CERTIFICADO_CREAR,
          recurso: persona,
          empresa: empresa,
          resultado: AuditEvent::RESULTADO_FALLO,
          mensaje: e.message,
          metadata: { persona_autorizada_id: persona&.id }
        )
        error_validacion(e.message)
      rescue StandardError => e
        auditar_evento_certificado(
          accion: Auditoria::Acciones::CERTIFICADO_CREAR,
          recurso: persona,
          empresa: empresa,
          resultado: AuditEvent::RESULTADO_FALLO,
          mensaje: e.message,
          metadata: { persona_autorizada_id: persona&.id }
        )
        error_interno("Error al crear certificado: #{e.message}")
      end

      # GET /api/v1/certificados/listar?persona_autorizada_id=&empresa_id=
      def listar
        certificados = if params[:empresa_id].present?
                         listar_por_empresa
                       elsif params[:persona_autorizada_id].present?
                         listar_por_persona
                       else
                         return error_parametros('Debe proporcionar persona_autorizada_id o empresa_id')
                       end

        return if performed?

        render_success(data: certificados.map { |cert| certificado_payload(cert) })
      end

      # POST /api/v1/certificados/verificar
      # Body: certificado_id
      def verificar
        return error_parametros('certificado_id es requerido') unless params[:certificado_id].present?

        certificado = Certificado.find_by(id: params[:certificado_id])
        return error_no_encontrado('Certificado no encontrado') unless certificado

        verificaciones = {
          archivo_crs_adjunto: certificado.archivo_crs.attached?,
          archivo_key_adjunto: certificado.archivo_key.attached?,
          clave_privada_valida: certificado.clave_privada.present?,
          certificado_x509_valido: certificado.certificado_x509.present?,
          vigente: certificado.vigente,
          completo: certificado.completo?,
          caducado: certificado.caducado?
        }

        info_cert = {}
        if verificaciones[:certificado_x509_valido]
          x509 = certificado.certificado_x509
          info_cert = {
            subject: x509.subject.to_s,
            issuer: x509.issuer.to_s,
            not_before: x509.not_before&.strftime('%Y-%m-%d'),
            not_after: x509.not_after&.strftime('%Y-%m-%d'),
            serial: x509.serial.to_s
          }
          certificado.update!(fecha_caducacion: x509.not_after) if x509.not_after.present?
        end

        utilizable = Certificados::ResolverParaEmpresa.certificado_utilizable?(certificado)
        todo_ok = verificaciones.values_at(
          :archivo_crs_adjunto,
          :archivo_key_adjunto,
          :clave_privada_valida,
          :certificado_x509_valido,
          :vigente,
          :completo
        ).all? && !verificaciones[:caducado]

        render_success(
          data: {
            certificado_id: certificado.id,
            persona_autorizada_id: certificado.persona_autorizada_id,
            certificado_valido: todo_ok,
            utilizable_para_firma: utilizable,
            verificaciones: verificaciones,
            info_certificado: info_cert
          },
          message: todo_ok ? 'Certificado listo para firmar' : 'Certificado incompleto o con errores'
        )
      rescue StandardError => e
        error_interno("Error al verificar certificado: #{e.message}")
      end

      # DELETE /api/v1/certificados/eliminar
      # Body/query: certificado_id
      def eliminar
        certificado = nil
        empresa = nil

        return error_parametros('certificado_id es requerido') unless params[:certificado_id].present?

        certificado = Certificado.find_by(id: params[:certificado_id])
        return error_no_encontrado('Certificado no encontrado') unless certificado

        empresa = empresa_para_certificado(certificado)
        certificado.update!(vigente: false)

        auditar_evento_certificado(
          accion: Auditoria::Acciones::CERTIFICADO_ELIMINAR,
          recurso: certificado,
          empresa: empresa,
          metadata: metadata_certificado(certificado, certificado.persona_autorizada),
          cambios: { 'vigente' => [true, false] }
        )

        render_success(message: 'Certificado desactivado exitosamente')
      rescue StandardError => e
        auditar_evento_certificado(
          accion: Auditoria::Acciones::CERTIFICADO_ELIMINAR,
          recurso: certificado,
          empresa: empresa,
          resultado: AuditEvent::RESULTADO_FALLO,
          mensaje: e.message
        ) if certificado
        error_interno("Error al eliminar certificado: #{e.message}")
      end

      private

      def require_administrador_fon!
        authorize_role!('administrador_fon')
      end

      def empresa_para_certificado(certificado)
        return Empresa.find_by(id: params[:empresa_id]) if params[:empresa_id].present?

        certificado.persona_autorizada.empresas.first
      end

      def metadata_certificado(certificado, persona)
        {
          persona_autorizada_id: persona.id,
          persona_rut: persona.rut,
          persona_nombre: persona.nombre_completo,
          certificado_id: certificado.is_a?(Certificado) ? certificado.id : nil,
          responsable: certificado.is_a?(Certificado) ? certificado.responsable : nil
        }
      end

      def listar_por_empresa
        empresa = Empresa.find_by(id: params[:empresa_id])
        return error_no_encontrado('Empresa no encontrada') unless empresa

        persona_ids = empresa.personas_autorizadas.pluck(:id)
        Certificado
          .includes(:persona_autorizada)
          .where(persona_autorizada_id: persona_ids)
          .order(fecha_adjuncion: :desc)
      end

      def listar_por_persona
        persona = PersonaAutorizada.find_by(id: params[:persona_autorizada_id])
        return error_no_encontrado('Persona autorizada no encontrada') unless persona

        persona.certificados.includes(:persona_autorizada).order(fecha_adjuncion: :desc)
      end

      def persona_vinculada_a_empresa?(persona, empresa)
        empresa.personas_autorizadas.exists?(id: persona.id)
      end

      def certificado_payload(certificado)
        persona = certificado.persona_autorizada

        {
          id: certificado.id,
          persona_autorizada_id: certificado.persona_autorizada_id,
          persona: {
            id: persona.id,
            rut: persona.rut,
            nombre_completo: persona.nombre_completo,
            orden: persona.orden
          },
          fecha_adjuncion: certificado.fecha_adjuncion&.strftime('%Y-%m-%d %H:%M:%S'),
          vigente: certificado.vigente,
          fecha_caducacion: certificado.fecha_caducacion&.strftime('%Y-%m-%d'),
          responsable: certificado.responsable,
          completo: certificado.completo?,
          caducado: certificado.caducado?,
          utilizable_para_firma: Certificados::ResolverParaEmpresa.certificado_utilizable?(certificado),
          archivo_crs_adjunto: certificado.archivo_crs.attached?,
          archivo_key_adjunto: certificado.archivo_key.attached?
        }
      end

      def attach_certificate_files!(certificado)
        crs_content = params[:archivo_crs].read
        key_content = params[:archivo_key].read
        storage_root = Rails.root.join('tmp', 'storage')

        crs_key = SecureRandom.alphanumeric(28)
        key_key = SecureRandom.alphanumeric(28)

        crs_path = storage_root.join(crs_key[0..1], crs_key[2..3], crs_key)
        key_path = storage_root.join(key_key[0..1], key_key[2..3], key_key)

        FileUtils.mkdir_p(File.dirname(crs_path))
        FileUtils.mkdir_p(File.dirname(key_path))
        File.binwrite(crs_path, crs_content)
        File.binwrite(key_path, key_content)

        crs_blob = ActiveStorage::Blob.create!(
          key: crs_key,
          filename: params[:archivo_crs].original_filename,
          content_type: 'application/x-pem-file',
          byte_size: crs_content.bytesize,
          checksum: Digest::MD5.base64digest(crs_content),
          service_name: Rails.application.config.active_storage.service.to_s
        )

        key_blob = ActiveStorage::Blob.create!(
          key: key_key,
          filename: params[:archivo_key].original_filename,
          content_type: 'application/x-pem-file',
          byte_size: key_content.bytesize,
          checksum: Digest::MD5.base64digest(key_content),
          service_name: Rails.application.config.active_storage.service.to_s
        )

        certificado.archivo_crs.attach(crs_blob)
        certificado.archivo_key.attach(key_blob)
      end

      def error_parametros(mensaje)
        render_error(mensaje, :bad_request, code: 'BAD_REQUEST')
      end

      def error_no_encontrado(mensaje)
        render_error(mensaje, :not_found, code: 'NOT_FOUND')
      end

      def error_validacion(mensaje)
        render_error(mensaje, :unprocessable_entity, code: 'VALIDATION_ERROR')
      end

      def error_interno(mensaje)
        Rails.logger.error(mensaje)
        render_error(mensaje, :internal_server_error, code: 'INTERNAL_ERROR')
      end
    end
  end
end

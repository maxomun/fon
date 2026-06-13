# frozen_string_literal: true

module Api
  module V1
    class CertificadosController < BaseController
      # Temporalmente sin autenticación para pruebas
      skip_before_action :authenticate_request!, only: [:crear, :listar, :verificar]

      # POST /api/v1/certificados/crear
      # Sube un nuevo certificado para un usuario (y por ende, para su empresa)
      #
      # Form-data esperado:
      #   user_id: ID del usuario
      #   archivo_crs: Archivo .crt o .pem (certificado público)
      #   archivo_key: Archivo .key o .pem (clave privada)
      #   frase_clave: Password de la clave privada
      #
      # Nota: Para convertir un .pfx/.p12:
      #   openssl pkcs12 -in cert.pfx -out cert.crt -nokeys -clcerts
      #   openssl pkcs12 -in cert.pfx -out cert.key -nocerts -nodes
      #
      def crear
        Rails.logger.info "=== CREAR CERTIFICADO: INICIO ==="
        
        # Validar parámetros requeridos
        return error_parametros('user_id es requerido') unless params[:user_id].present?
        return error_parametros('archivo_crs es requerido') unless params[:archivo_crs].present?
        return error_parametros('archivo_key es requerido') unless params[:archivo_key].present?
        return error_parametros('frase_clave es requerida') unless params[:frase_clave].present?

        Rails.logger.info "=== PASO 1: Parámetros validados ==="

        # Buscar usuario
        user = User.find_by(id: params[:user_id])
        return error_no_encontrado('Usuario no encontrado') unless user

        Rails.logger.info "=== PASO 2: Usuario encontrado: #{user.id} ==="

        # Verificar que el usuario pertenece a una empresa
        return error_validacion('El usuario no tiene empresa asignada') unless user.empresa_id.present?

        Rails.logger.info "=== PASO 3: Usuario tiene empresa: #{user.empresa_id} ==="

        Certificado.transaction do
          Rails.logger.info "=== PASO 4: Inicio transaction ==="
          
          # Desactivar certificados anteriores del usuario
          user.certificados.vigentes.update_all(vigente: false)
          Rails.logger.info "=== PASO 5: Certificados anteriores desactivados ==="

          # Crear nuevo certificado
          certificado = Certificado.new(
            user_id: user.id,
            fecha_adjuncion: Time.current,
            vigente: true,
            fecha_caducacion: nil,
            frase_clave: params[:frase_clave],
            responsable: user.username
          )
          Rails.logger.info "=== PASO 6: Certificado instanciado ==="

          # Leer contenido de los archivos
          crs_content = params[:archivo_crs].read
          key_content = params[:archivo_key].read
          Rails.logger.info "=== PASO 7: Archivos leídos (crs: #{crs_content.bytesize} bytes, key: #{key_content.bytesize} bytes) ==="

          # Guardar archivos manualmente (evitar problemas de Active Storage con directorios)
          storage_root = Rails.root.join('tmp', 'storage')
          
          crs_key = SecureRandom.alphanumeric(28)
          key_key = SecureRandom.alphanumeric(28)
          
          crs_path = storage_root.join(crs_key[0..1], crs_key[2..3], crs_key)
          key_path = storage_root.join(key_key[0..1], key_key[2..3], key_key)
          Rails.logger.info "=== PASO 8: Paths generados ==="
          
          # Crear directorios
          FileUtils.mkdir_p(File.dirname(crs_path))
          FileUtils.mkdir_p(File.dirname(key_path))
          Rails.logger.info "=== PASO 9: Directorios creados ==="
          
          # Escribir archivos
          File.binwrite(crs_path, crs_content)
          File.binwrite(key_path, key_content)
          Rails.logger.info "=== PASO 10: Archivos escritos en disco ==="
          
          # Crear blobs manualmente
          crs_blob = ActiveStorage::Blob.create!(
            key: crs_key,
            filename: params[:archivo_crs].original_filename,
            content_type: 'application/x-pem-file',
            byte_size: crs_content.bytesize,
            checksum: Digest::MD5.base64digest(crs_content),
            service_name: 'test'
          )
          Rails.logger.info "=== PASO 11: Blob CRS creado: #{crs_blob.id} ==="
          
          key_blob = ActiveStorage::Blob.create!(
            key: key_key,
            filename: params[:archivo_key].original_filename,
            content_type: 'application/x-pem-file',
            byte_size: key_content.bytesize,
            checksum: Digest::MD5.base64digest(key_content),
            service_name: 'test'
          )
          Rails.logger.info "=== PASO 12: Blob KEY creado: #{key_blob.id} ==="
          
          # Asociar blobs al certificado
          certificado.archivo_crs.attach(crs_blob)
          certificado.archivo_key.attach(key_blob)
          Rails.logger.info "=== PASO 13: Blobs asociados ==="
          
          # Guardar primero para persistir los attachments
          certificado.save!
          Rails.logger.info "=== PASO 14: Certificado guardado: #{certificado.id} ==="
          
          # Verificar que se puede cargar la clave privada
          Rails.logger.info "=== PASO 15: Verificando clave privada... ==="
          unless certificado.clave_privada
            Rails.logger.info "=== ERROR: Clave privada inválida ==="
            # Eliminar el certificado si la clave no es válida
            certificado.destroy
            raise StandardError, 'No se pudo cargar la clave privada. Verifique la frase clave.'
          end
          Rails.logger.info "=== PASO 16: Clave privada verificada OK ==="

          render json: {
            success: true,
            message: 'Certificado creado exitosamente',
            data: {
              id: certificado.id,
              user_id: certificado.user_id,
              empresa_id: user.empresa_id,
              fecha_adjuncion: certificado.fecha_adjuncion&.strftime('%Y-%m-%d %H:%M:%S'),
              vigente: certificado.vigente,
              responsable: certificado.responsable,
              archivo_crs_adjunto: certificado.archivo_crs.attached?,
              archivo_key_adjunto: certificado.archivo_key.attached?
            }
          }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        error_validacion(e.message)
      rescue StandardError => e
        error_interno("Error al crear certificado: #{e.message}")
      end

      # GET /api/v1/certificados/listar
      # Lista los certificados de un usuario o empresa
      #
      # Query params:
      #   user_id: ID del usuario (opcional)
      #   empresa_id: ID de la empresa (opcional)
      #
      def listar
        certificados =  if params[:empresa_id].present?
                          empresa = Empresa.find_by(id: params[:empresa_id])
                          return error_no_encontrado('Empresa no encontrada') unless empresa

                          empresa.certificados
                        elsif params[:user_id].present?
                          user = User.find_by(id: params[:user_id])
                          return error_no_encontrado('Usuario no encontrado') unless user

                          user.certificados
                        else
                          return error_parametros('Debe proporcionar user_id o empresa_id')
                        end

        render json: {
          success: true,
          data: certificados.map do |cert|
            {
              id: cert.id,
              user_id: cert.user_id,
              fecha_adjuncion: cert.fecha_adjuncion&.strftime('%Y-%m-%d'),
              vigente: cert.vigente,
              fecha_caducacion: cert.fecha_caducacion&.strftime('%Y-%m-%d'),
              responsable: cert.responsable,
              completo: cert.completo?
            }
          end
        }
      end

      # POST /api/v1/certificados/verificar
      # Verifica que un certificado esté correctamente configurado
      #
      # Body esperado:
      #   certificado_id: ID del certificado a verificar
      #
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
          completo: certificado.completo?
        }

        # Información adicional si el certificado X509 es válido
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
        end

        todo_ok = verificaciones.values.all?

        render json: {
          success: true,
          certificado_valido: todo_ok,
          verificaciones: verificaciones,
          info_certificado: info_cert,
          mensaje: todo_ok ? 'Certificado listo para firmar' : 'Certificado incompleto o con errores'
        }
      rescue StandardError => e
        error_interno("Error al verificar certificado: #{e.message}")
      end

      # DELETE /api/v1/certificados/eliminar
      # Elimina (desactiva) un certificado
      #
      def eliminar
        return error_parametros('certificado_id es requerido') unless params[:certificado_id].present?

        certificado = Certificado.find_by(id: params[:certificado_id])
        return error_no_encontrado('Certificado no encontrado') unless certificado

        certificado.update!(vigente: false)

        render json: {
          success: true,
          message: 'Certificado desactivado exitosamente'
        }
      rescue StandardError => e
        error_interno("Error al eliminar certificado: #{e.message}")
      end

      private

      def error_parametros(mensaje)
        render json: { success: false, error: mensaje }, status: :bad_request
      end

      def error_no_encontrado(mensaje)
        render json: { success: false, error: mensaje }, status: :not_found
      end

      def error_validacion(mensaje)
        render json: { success: false, error: mensaje }, status: :unprocessable_entity
      end

      def error_interno(mensaje)
        Rails.logger.error(mensaje)
        render json: { success: false, error: mensaje }, status: :internal_server_error
      end
    end
  end
end

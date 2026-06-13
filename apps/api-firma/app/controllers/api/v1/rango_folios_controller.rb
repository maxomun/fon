# frozen_string_literal: true

module Api
  module V1
    class RangoFoliosController < ApplicationController
      include Authenticable

      skip_before_action :authenticate_request!, only: [:cargar, :listar, :obtener, :eliminar]

      # POST /api/v1/rango_folios/cargar
      # Carga un archivo CAF (XML del SII) y crea el rango de folios
      #
      # Form-data:
      #   archivo: archivo CAF (XML)
      #   empresa_id: ID de la empresa
      #
      def cargar
        Rails.logger.info "=== RANGO_FOLIOS: Iniciando carga de CAF ==="

        # Validar parámetros
        unless params[:archivo].present?
          return render json: { success: false, error: 'Debe adjuntar un archivo CAF' }, status: :unprocessable_entity
        end

        unless params[:empresa_id].present?
          return render json: { success: false, error: 'empresa_id es requerido' }, status: :unprocessable_entity
        end

        empresa = Empresa.find_by(id: params[:empresa_id])
        unless empresa
          return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found
        end

        archivo = params[:archivo]
        nombre_original = archivo.original_filename

        # Verificar que sea un archivo XML
        unless nombre_original.downcase.end_with?('.xml')
          return render json: { success: false, error: 'El archivo debe ser un XML' }, status: :unprocessable_entity
        end

        # Verificar si el archivo ya existe
        if RangoFolio.exists?(archivo: nombre_original, empresa_id: empresa.id)
          return render json: { success: false, error: 'Este archivo CAF ya fue cargado para esta empresa' }, status: :unprocessable_entity
        end

        # Parsear el XML CAF
        begin
          contenido = archivo.read
          archivo.rewind
          doc = Nokogiri::XML(contenido)

          # Extraer valores del CAF
          td = doc.xpath('//TD').first&.content
          d = doc.xpath('//D').first&.content&.to_i
          h = doc.xpath('//H').first&.content&.to_i
          fa = doc.xpath('//FA').first&.content
          rsask = doc.xpath('//RSASK').first&.content
          rsapubk = doc.xpath('//RSAPUBK').first&.content

          Rails.logger.info "=== CAF: TD=#{td}, D=#{d}, H=#{h}, FA=#{fa} ==="

          # Validar que todos los campos existan
          campos_faltantes = []
          campos_faltantes << 'TD (Tipo Documento)' if td.blank?
          campos_faltantes << 'D (Desde)' if d.nil? || d == 0
          campos_faltantes << 'H (Hasta)' if h.nil? || h == 0
          campos_faltantes << 'FA (Fecha Autorización)' if fa.blank?
          campos_faltantes << 'RSASK (Clave Privada)' if rsask.blank?
          campos_faltantes << 'RSAPUBK (Clave Pública)' if rsapubk.blank?

          if campos_faltantes.any?
            return render json: {
              success: false,
              error: "El archivo CAF no contiene los campos requeridos: #{campos_faltantes.join(', ')}"
            }, status: :unprocessable_entity
          end

          # Buscar TipoDocumento
          tipo_documento = TipoDocumento.find_by(codigo: td)
          unless tipo_documento
            return render json: {
              success: false,
              error: "Tipo de documento #{td} no encontrado en el sistema"
            }, status: :unprocessable_entity
          end

          # Verificar que el tipo esté habilitado para la empresa
          tipo_habilitado = TipoHabilitado.find_by(empresa_id: empresa.id, tipo_documento_id: tipo_documento.id)
          unless tipo_habilitado
            return render json: {
              success: false,
              error: "El tipo de documento #{td} (#{tipo_documento.nombre}) no está habilitado para esta empresa. Debe habilitarlo primero."
            }, status: :unprocessable_entity
          end

          # Verificar que no se traslapen rangos
          rango_existente = RangoFolio.where(tipo_habilitado_id: tipo_habilitado.id)
                                       .where('(d <= ? AND h >= ?) OR (d <= ? AND h >= ?) OR (d >= ? AND h <= ?)',
                                              d, d, h, h, d, h)
                                       .first
          if rango_existente
            return render json: {
              success: false,
              error: "Ya existe un rango de folios (#{rango_existente.d}-#{rango_existente.h}) que se traslapa con este rango (#{d}-#{h})"
            }, status: :unprocessable_entity
          end

          # Usuario actual o sistema
          username = current_user&.email || 'sistema'

          # Crear RangoFolio y Folios en transacción
          rango_folio = nil
          RangoFolio.transaction do
            rango_folio = RangoFolio.create!(
              empresa_id: empresa.id,
              td: td,
              d: d,
              h: h,
              fa: Date.strptime(fa, '%Y-%m-%d'),
              rsask: rsask,
              rsapubk: rsapubk,
              tipo_habilitado_id: tipo_habilitado.id,
              fecha_uso: nil,
              archivo: nombre_original,
              username: username,
              fecha_subida: Time.current
            )

            Rails.logger.info "=== RangoFolio creado: #{rango_folio.id} ==="

            # Crear folios individuales
            folios_creados = 0
            (d..h).each do |numero|
              Folio.create!(
                numero: numero,
                disponible: true,
                reservado: false,
                usado: false,
                anulado: false,
                rango_folio_id: rango_folio.id,
                empresa_id: empresa.id,
                tipo_habilitado_id: tipo_habilitado.id
              )
              folios_creados += 1
            end

            Rails.logger.info "=== Folios creados: #{folios_creados} ==="

            # Guardar archivo CAF usando método manual (evitar problemas de Active Storage)
            guardar_archivo_caf(rango_folio, archivo, nombre_original)
          end

          render json: {
            success: true,
            message: 'Archivo CAF cargado correctamente',
            data: {
              rango_folio_id: rango_folio.id,
              tipo_documento: {
                codigo: td,
                nombre: tipo_documento.nombre
              },
              rango: {
                desde: d,
                hasta: h,
                cantidad: h - d + 1
              },
              fecha_autorizacion: fa,
              empresa: empresa.razon_social
            }
          }, status: :created

        rescue Date::Error => e
          render json: { success: false, error: "Formato de fecha inválido en el CAF: #{e.message}" }, status: :unprocessable_entity
        rescue ActiveRecord::RecordInvalid => e
          render json: { success: false, error: "Error de validación: #{e.message}" }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error "=== Error cargando CAF: #{e.message} ==="
          Rails.logger.error e.backtrace.first(10).join("\n")
          render json: { success: false, error: e.message }, status: :internal_server_error
        end
      end

      # GET /api/v1/rango_folios/listar
      # Lista los rangos de folio de una empresa
      #
      # Params:
      #   empresa_id: ID de la empresa
      #
      def listar
        unless params[:empresa_id].present?
          return render json: { success: false, error: 'empresa_id es requerido' }, status: :unprocessable_entity
        end

        empresa = Empresa.find_by(id: params[:empresa_id])
        unless empresa
          return render json: { success: false, error: 'Empresa no encontrada' }, status: :not_found
        end

        rangos = RangoFolio.where(empresa_id: empresa.id)
                           .includes(:tipo_habilitado, tipo_habilitado: :tipo_documento)
                           .order(created_at: :desc)

        lista = rangos.map do |r|
          tipo_doc = r.tipo_habilitado&.tipo_documento
          {
            id: r.id,
            tipo_documento: {
              codigo: r.td,
              nombre: tipo_doc&.nombre
            },
            rango: {
              desde: r.d,
              hasta: r.h,
              cantidad: r.cantidad_folios
            },
            folios: {
              disponibles: r.folios_disponibles.count,
              usados: r.folios_usados.count,
              total: r.folios.count
            },
            fecha_autorizacion: r.fa&.strftime('%Y-%m-%d'),
            fecha_subida: r.fecha_subida&.strftime('%Y-%m-%d %H:%M'),
            fecha_ultimo_uso: r.fecha_uso&.strftime('%Y-%m-%d %H:%M'),
            subido_por: r.username,
            archivo: r.archivo
          }
        end

        render json: {
          success: true,
          data: lista,
          total: lista.count
        }, status: :ok
      end

      # GET /api/v1/rango_folios/obtener
      # Obtiene detalle de un rango de folio
      #
      # Params:
      #   id: ID del rango de folio
      #
      def obtener
        unless params[:id].present?
          return render json: { success: false, error: 'id es requerido' }, status: :unprocessable_entity
        end

        rango = RangoFolio.includes(:tipo_habilitado, :empresa, tipo_habilitado: :tipo_documento)
                          .find_by(id: params[:id])

        unless rango
          return render json: { success: false, error: 'Rango de folio no encontrado' }, status: :not_found
        end

        tipo_doc = rango.tipo_habilitado&.tipo_documento

        # Obtener estadísticas de folios
        folios_stats = {
          disponibles: rango.folios.disponibles.count,
          usados: rango.folios.usados.count,
          anulados: rango.folios.anulados.count,
          reservados: rango.folios.reservados.count,
          total: rango.folios.count
        }

        # Próximo folio disponible
        proximo_folio = rango.folios.disponibles.order(:numero).first

        render json: {
          success: true,
          data: {
            id: rango.id,
            empresa: {
              id: rango.empresa_id,
              razon_social: rango.empresa&.razon_social,
              rut: rango.empresa&.rut
            },
            tipo_documento: {
              codigo: rango.td,
              nombre: tipo_doc&.nombre
            },
            rango: {
              desde: rango.d,
              hasta: rango.h,
              cantidad: rango.cantidad_folios
            },
            folios: folios_stats,
            proximo_folio_disponible: proximo_folio&.numero,
            fecha_autorizacion: rango.fa&.strftime('%Y-%m-%d'),
            fecha_subida: rango.fecha_subida&.strftime('%Y-%m-%d %H:%M:%S'),
            fecha_ultimo_uso: rango.fecha_uso&.strftime('%Y-%m-%d %H:%M:%S'),
            subido_por: rango.username,
            archivo_nombre: rango.archivo
          }
        }, status: :ok
      end

      # DELETE /api/v1/rango_folios/eliminar
      # Elimina un rango de folio y sus folios asociados
      #
      # Params:
      #   id: ID del rango de folio
      #
      def eliminar
        unless params[:id].present?
          return render json: { success: false, error: 'id es requerido' }, status: :unprocessable_entity
        end

        rango = RangoFolio.find_by(id: params[:id])
        unless rango
          return render json: { success: false, error: 'Rango de folio no encontrado' }, status: :not_found
        end

        # Verificar que no tenga folios usados
        if rango.folios.usados.exists?
          return render json: {
            success: false,
            error: 'No se puede eliminar un rango que tiene folios usados',
            folios_usados: rango.folios.usados.count
          }, status: :unprocessable_entity
        end

        info_rango = {
          id: rango.id,
          tipo_documento: rango.td,
          rango: "#{rango.d}-#{rango.h}",
          folios_eliminados: rango.folios.count
        }

        rango.destroy!

        render json: {
          success: true,
          message: 'Rango de folio eliminado correctamente',
          data: info_rango
        }, status: :ok

      rescue StandardError => e
        render json: { success: false, error: e.message }, status: :internal_server_error
      end

      private

      def guardar_archivo_caf(rango_folio, archivo, nombre_original)
        contenido = archivo.read
        archivo.rewind

        storage_root = Rails.root.join('tmp', 'storage')
        caf_key = SecureRandom.alphanumeric(28)
        caf_path = storage_root.join(caf_key[0..1], caf_key[2..3], caf_key)

        FileUtils.mkdir_p(File.dirname(caf_path))
        File.binwrite(caf_path, contenido)

        caf_blob = ActiveStorage::Blob.create!(
          key: caf_key,
          filename: nombre_original,
          content_type: 'application/xml',
          byte_size: contenido.bytesize,
          checksum: Digest::MD5.base64digest(contenido),
          service_name: 'test'
        )

        rango_folio.archivo_rango_folio.attach(caf_blob)
        Rails.logger.info "=== Archivo CAF guardado: #{caf_path} ==="
      end
    end
  end
end

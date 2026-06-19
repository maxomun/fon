# frozen_string_literal: true

module RangosFolios
  class ImportarCaf
    Result = Struct.new(:rango_folio, :errors, keyword_init: true) do
      def success?
        errors.blank? && rango_folio&.persisted?
      end
    end

    def self.call(empresa:, archivo:, username:)
      new(empresa: empresa, archivo: archivo, username: username).call
    end

    def initialize(empresa:, archivo:, username:)
      @empresa = empresa
      @archivo = archivo
      @username = username
    end

    def call
      return failure('Debe adjuntar un archivo CAF') if @archivo.blank?

      nombre_original = @archivo.original_filename.to_s
      return failure('El archivo debe ser un XML') unless nombre_original.downcase.end_with?('.xml')

      if RangoFolio.exists?(archivo: nombre_original, empresa_id: @empresa.id)
        return failure('Este archivo CAF ya fue cargado para esta empresa')
      end

      contenido = @archivo.read
      @archivo.rewind
      doc = Nokogiri::XML(contenido)

      re = doc.xpath('//DA/RE').first&.content.presence || doc.xpath('//RE').first&.content
      td = doc.xpath('//TD').first&.content
      d = doc.xpath('//D').first&.content&.to_i
      h = doc.xpath('//H').first&.content&.to_i
      fa = doc.xpath('//FA').first&.content
      rsask = doc.xpath('//RSASK').first&.content
      rsapubk = doc.xpath('//RSAPUBK').first&.content

      campos_faltantes = []
      campos_faltantes << 'RE (RUT Emisor)' if re.blank?
      campos_faltantes << 'TD (Tipo Documento)' if td.blank?
      campos_faltantes << 'D (Desde)' if d.nil? || d.zero?
      campos_faltantes << 'H (Hasta)' if h.nil? || h.zero?
      campos_faltantes << 'FA (Fecha Autorización)' if fa.blank?
      campos_faltantes << 'RSASK (Clave Privada)' if rsask.blank?
      campos_faltantes << 'RSAPUBK (Clave Pública)' if rsapubk.blank?

      if campos_faltantes.any?
        return failure("El archivo CAF no contiene los campos requeridos: #{campos_faltantes.join(', ')}")
      end

      unless rut_coincide?(re, @empresa.rut)
        return failure(
          "El RUT del CAF (#{re}) no corresponde al RUT de la empresa (#{@empresa.rut})"
        )
      end

      tipo_documento = TipoDocumento.find_by(codigo: td)
      return failure("Tipo de documento #{td} no encontrado en el sistema") unless tipo_documento

      tipo_habilitado = TipoHabilitado.find_by(
        empresa_id: @empresa.id,
        tipo_documento_id: tipo_documento.id
      )
      unless tipo_habilitado
        return failure(
          "El tipo de documento #{td} (#{tipo_documento.nombre}) no está habilitado para esta empresa. " \
          'Debe habilitarlo primero.'
        )
      end

      rango_existente = RangoFolio.where(tipo_habilitado_id: tipo_habilitado.id)
                                  .where(
                                    '(d <= ? AND h >= ?) OR (d <= ? AND h >= ?) OR (d >= ? AND h <= ?)',
                                    d, d, h, h, d, h
                                  )
                                  .first
      if rango_existente
        return failure(
          "Ya existe un rango de folios (#{rango_existente.d}-#{rango_existente.h}) " \
          "que se traslapa con este rango (#{d}-#{h})"
        )
      end

      rango_folio = nil
      RangoFolio.transaction do
        rango_folio = RangoFolio.create!(
          empresa_id: @empresa.id,
          td: td,
          d: d,
          h: h,
          fa: Date.strptime(fa, '%Y-%m-%d'),
          rsask: rsask,
          rsapubk: rsapubk,
          tipo_habilitado_id: tipo_habilitado.id,
          fecha_uso: nil,
          archivo: nombre_original,
          username: @username,
          fecha_subida: Time.current
        )

        (d..h).each do |numero|
          Folio.create!(
            numero: numero,
            disponible: true,
            reservado: false,
            usado: false,
            anulado: false,
            rango_folio_id: rango_folio.id,
            empresa_id: @empresa.id,
            tipo_habilitado_id: tipo_habilitado.id
          )
        end

        guardar_archivo_caf(rango_folio, contenido, nombre_original)
      end

      Result.new(rango_folio: rango_folio, errors: [])
    rescue Date::Error => e
      failure("Formato de fecha inválido en el CAF: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("Error cargando CAF: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      failure(e.message)
    end

    private

    def failure(errors)
      Result.new(rango_folio: nil, errors: Array(errors))
    end

    def rut_coincide?(rut_caf, rut_empresa)
      normalizar_rut(rut_caf) == normalizar_rut(rut_empresa)
    end

    def normalizar_rut(rut)
      return '' if rut.blank?

      rut.to_s.gsub(/[.\s]/, '').upcase
    end

    def guardar_archivo_caf(rango_folio, contenido, nombre_original)
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
    end
  end
end

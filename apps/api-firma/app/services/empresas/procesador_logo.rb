# frozen_string_literal: true

require 'image_processing/vips'

module Empresas
  class ProcesadorLogo
    class Error < StandardError
      attr_reader :code

      def initialize(message, code: 'VALIDATION_ERROR')
        super(message)
        @code = code
      end
    end

    Result = Struct.new(:metadata, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    MAX_UPLOAD_BYTES = 5.megabytes
    MAX_STORED_BYTES = 150.kilobytes
    TARGET_WIDTH = 540
    TARGET_HEIGHT = 180
    MIN_WIDTH = 180
    MIN_HEIGHT = 60
    MIN_ASPECT_RATIO = 2.0
    MAX_ASPECT_RATIO = 4.0
    ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

    def self.call(empresa:, archivo:)
      new(empresa: empresa, archivo: archivo).call
    end

    def initialize(empresa:, archivo:)
      @empresa = empresa
      @archivo = archivo
    end

    def call
      validate_presence!
      validate_upload_size!
      validate_content_type!

      Tempfile.create(['logo_orig', extension]) do |origen|
        copiar_archivo!(origen)
        validate_dimensions!(origen.path)

        processed = process_image(origen.path)
        attach_logo!(processed)

        Result.new(metadata: metadata_logo, errors: nil)
      end
    rescue Error => e
      Result.new(metadata: nil, errors: [e.message])
    rescue Vips::Error
      Result.new(metadata: nil, errors: ['El archivo no es una imagen válida'])
    end

    private

    attr_reader :empresa, :archivo

    def validate_presence!
      raise Error, 'Debe adjuntar un archivo de logo' if archivo.blank?
    end

    def validate_upload_size!
      size = archivo.respond_to?(:size) ? archivo.size : File.size(archivo.path)
      return if size <= MAX_UPLOAD_BYTES

      raise Error, "El archivo supera el máximo de #{MAX_UPLOAD_BYTES / 1.megabyte} MB"
    end

    def validate_content_type!
      tipo = archivo.content_type.to_s.downcase
      return if ALLOWED_CONTENT_TYPES.include?(tipo)

      raise Error, 'Formato no permitido. Use PNG, JPEG o WebP'
    end

    def copiar_archivo!(destino)
      archivo.rewind if archivo.respond_to?(:rewind)
      destino.binmode
      IO.copy_stream(archivo, destino)
      destino.flush
    end

    def validate_dimensions!(path)
      image = Vips::Image.new_from_file(path, access: :sequential)
      width = image.width
      height = image.height

      if width < MIN_WIDTH || height < MIN_HEIGHT
        raise Error,
              "La imagen es muy pequeña (mínimo #{MIN_WIDTH}×#{MIN_HEIGHT} px)"
      end

      aspect = width.to_f / height
      unless aspect.between?(MIN_ASPECT_RATIO, MAX_ASPECT_RATIO)
        raise Error,
              "La proporción debe ser horizontal (~3:1). Obtuvo #{width}×#{height} (#{aspect.round(2)}:1)"
      end
    end

    def process_image(source_path)
      image = Vips::Image.new_from_file(source_path, access: :sequential)
      has_alpha = image.has_alpha?

      if has_alpha
        encode_png(source_path)
      else
        encode_jpeg(source_path)
      end
    end

    def encode_png(source_path)
      [9, 6].each do |compression|
        processed = ImageProcessing::Vips
                    .source(source_path)
                    .resize_to_limit(TARGET_WIDTH, TARGET_HEIGHT)
                    .convert('png')
                    .saver(strip: true, compression: compression)
                    .call

        return processed if File.size(processed.path) <= MAX_STORED_BYTES

        processed.close!
      end

      raise Error, "No se pudo optimizar el logo por debajo de #{MAX_STORED_BYTES / 1.kilobyte} KB"
    end

    def encode_jpeg(source_path)
      [85, 75, 65, 55].each do |quality|
        processed = ImageProcessing::Vips
                    .source(source_path)
                    .resize_to_limit(TARGET_WIDTH, TARGET_HEIGHT)
                    .convert('jpg')
                    .saver(strip: true, quality: quality, interlace: true)
                    .call

        return processed if File.size(processed.path) <= MAX_STORED_BYTES

        processed.close!
      end

      raise Error, "No se pudo optimizar el logo por debajo de #{MAX_STORED_BYTES / 1.kilobyte} KB"
    end

    def attach_logo!(processed)
      ActiveStorage::EliminadorSinPurge.call(record: empresa, name: :logo)

      filename = "logo_empresa_#{empresa.id}#{File.extname(processed.path)}"
      content_type = processed.path.end_with?('.png') ? 'image/png' : 'image/jpeg'

      File.open(processed.path, 'rb') do |io|
        empresa.logo.attach(
          io: io,
          filename: filename,
          content_type: content_type
        )
      end

      empresa.update!(archivo_logo: filename)
      @attached_metadata = build_metadata(processed.path, content_type)
    ensure
      processed.close! if processed
    end

    def metadata_logo
      @attached_metadata || build_metadata_from_attachment
    end

    def build_metadata_from_attachment
      blob = empresa.logo.blob
      {
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size
      }
    end

    def build_metadata(path, content_type)
      image = Vips::Image.new_from_file(path, access: :sequential)
      {
        filename: File.basename(path),
        content_type: content_type,
        byte_size: File.size(path),
        width: image.width,
        height: image.height
      }
    end

    def extension
      case archivo.content_type.to_s.downcase
      when 'image/png' then '.png'
      when 'image/webp' then '.webp'
      else '.jpg'
      end
    end
  end
end

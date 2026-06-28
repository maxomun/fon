# frozen_string_literal: true

require 'open3'
require 'tmpdir'
require 'pathname'

module Dte
  module Pdf
    # Genera imagen PNG del timbre PDF417 a partir del string TED (modo binario, ECL 5).
    class GeneradorPdf417
      def self.script_path
        if defined?(Rails) && Rails.respond_to?(:root)
          Rails.root.join('script/generar_pdf417.js')
        else
          Pathname.new(File.expand_path('../../../../script/generar_pdf417.js', __dir__))
        end
      end

      def self.call(ted_string:)
        new(ted_string: ted_string).call
      end

      def initialize(ted_string:)
        @ted_string = ted_string
        @script = self.class.script_path
      end

      def call
        return nil if ted_string.to_s.empty?
        return nil unless @script.exist?

        Dir.mktmpdir('ted_pdf417') do |dir|
          input = File.join(dir, 'ted.dat')
          output = File.join(dir, 'ted.png')
          File.binwrite(input, ted_string.b.force_encoding('ASCII-8BIT'))

          _stdout, stderr, status = Open3.capture3('node', @script.to_s, input, output)
          unless status.success? && File.exist?(output)
            log_warn(stderr.to_s.empty? ? 'sin salida' : stderr.to_s)
            return nil
          end

          File.binread(output)
        end
      rescue StandardError => e
        log_warn("#{e.class}: #{e.message}")
        nil
      end

      private

      attr_reader :ted_string

      def log_warn(message)
        if defined?(Rails) && Rails.respond_to?(:logger)
          Rails.logger.warn("[Dte::Pdf::GeneradorPdf417] #{message}")
        else
          warn("[Dte::Pdf::GeneradorPdf417] #{message}")
        end
      end
    end
  end
end

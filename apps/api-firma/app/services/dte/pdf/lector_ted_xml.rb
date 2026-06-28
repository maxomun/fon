# frozen_string_literal: true

require 'nokogiri'

module Dte
  module Pdf
    # Extrae el nodo <TED> firmado del DTE que corresponde al folio en un EnvioDTE.
    class LectorTedXml
      NS = { 'xmlns' => GeneradorXml::NAMESPACE }.freeze

      def self.call(xml_string:, folio:)
        new(xml_string: xml_string, folio: folio).call
      end

      def initialize(xml_string:, folio:)
        @xml_string = xml_string
        @folio = folio.to_i
      end

      def call
        doc = Nokogiri::XML(xml_string)
        doc.encoding = 'ISO-8859-1'

        doc.xpath('//xmlns:DTE', NS).each do |dte|
          folio_nodo = dte.at_xpath('.//xmlns:IdDoc/xmlns:Folio', NS)
          next unless folio_nodo&.text.to_i == folio

          ted = dte.at_xpath('.//xmlns:TED', NS)
          return ted if ted

          break
        end

        nil
      end

      private

      attr_reader :xml_string, :folio
    end
  end
end

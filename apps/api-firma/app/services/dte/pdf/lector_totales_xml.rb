# frozen_string_literal: true

require 'nokogiri'

module Dte
  module Pdf
    # Lee totales y fecha de emisión del nodo DTE correspondiente al folio en un EnvioDTE firmado.
    class LectorTotalesXml
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

          totales_nodo = dte.at_xpath('.//xmlns:Totales', NS)
          next unless totales_nodo

          return {
            neto_afecto: entero(totales_nodo, 'MntNeto'),
            neto_exento: entero(totales_nodo, 'MntExe'),
            iva: entero(totales_nodo, 'IVA'),
            total: entero(totales_nodo, 'MntTotal'),
            fecha_emision: dte.at_xpath('.//xmlns:IdDoc/xmlns:FchEmis', NS)&.text
          }
        end

        nil
      end

      private

      attr_reader :xml_string, :folio

      def entero(totales_nodo, nombre)
        totales_nodo.at_xpath("xmlns:#{nombre}", NS)&.text.to_i
      end
    end
  end
end

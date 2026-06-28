# frozen_string_literal: true

require 'nokogiri'

module Dte
  module Pdf
    # Serializa el nodo TED para el código PDF417 (misma lógica que LibreDTE::Dte::getTED).
    # C14N → quitar namespaces → colapsar espacios entre tags → ISO-8859-1.
    class SerializadorTed
      def self.call(ted_node:)
        new(ted_node: ted_node).call
      end

      def initialize(ted_node:)
        @ted_node = ted_node
      end

      def call
        return nil unless ted_node

        doc = Nokogiri::XML(ted_node.canonicalize)
        doc.encoding = 'ISO-8859-1'
        root = doc.root
        return nil unless root

        quitar_namespaces!(root)

        aplanado = root.canonicalize
        aplanado = aplanado.gsub(/>\s+</m, '><').strip
        aplanado.force_encoding('ISO-8859-1')
      end

      private

      attr_reader :ted_node

      def quitar_namespaces!(node)
        node.remove_attribute('xmlns')
        node.remove_attribute('xmlns:xsi')
        node.remove_attribute('xsi:schemaLocation')
        node.children.each { |child| quitar_namespaces!(child) if child.element? }
      end
    end
  end
end

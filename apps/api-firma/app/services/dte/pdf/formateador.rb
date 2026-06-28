# frozen_string_literal: true

module Dte
  module Pdf
    module Formateador
      module_function

      def moneda(valor)
        numero = valor.to_i
        signo = numero.negative? ? '-' : ''
        absoluto = numero.abs
        "#{signo}$#{absoluto.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"
      end

      def porcentaje(valor)
        numero = valor.to_f
        return numero.to_i.to_s if numero == numero.to_i

        numero.to_s
      end

      def rut(valor)
        valor.to_s.gsub(/[.\s]/, '')
      end
    end
  end
end

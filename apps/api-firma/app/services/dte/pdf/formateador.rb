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

      def rut_con_puntos(valor)
        limpio = rut(valor).upcase
        return limpio if limpio.empty?

        cuerpo, dv = limpio.split('-', 2)
        if dv.nil?
          cuerpo = limpio[0..-2]
          dv = limpio[-1]
        end

        cuerpo_formateado = cuerpo.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
        "#{cuerpo_formateado}-#{dv}"
      end

      def folio(valor)
        valor.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
      end
    end
  end
end

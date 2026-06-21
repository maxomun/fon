# frozen_string_literal: true

module PersonasAutorizadas
  # Normaliza nombres y apellidos a formato de nombre propio (Title Case).
  #
  # Ejemplo:
  #   NormalizarNombres.call(nombres: "JUAN emilio", apellido_paterno: "PEREZ")
  #   # => { nombres: "Juan Emilio", apellido_paterno: "Perez", ... }
  #
  class NormalizarNombres
    PARTICULAS = %w[de del la las lo los y e en].freeze

    def self.call(nombres:, apellido_paterno: nil, apellido_materno: nil)
      {
        nombres: normalizar_campo(nombres),
        apellido_paterno: normalizar_campo(apellido_paterno),
        apellido_materno: normalizar_campo(apellido_materno)
      }
    end

    def self.normalizar_campo(valor)
      return valor if valor.blank?

      valor
        .to_s
        .strip
        .split(/\s+/)
        .map
        .with_index { |palabra, index| formatear_palabra(palabra, index.zero?) }
        .join(' ')
    end

    def self.formatear_palabra(palabra, primera_del_campo)
      base = palabra.downcase
      return base.capitalize if primera_del_campo
      return base if PARTICULAS.include?(base)

      base.capitalize
    end

    private_class_method :normalizar_campo, :formatear_palabra
  end
end

# frozen_string_literal: true

module Dte
  # Servicio para clasificar items en páginas según el espacio disponible
  # Usa Prawn para simular el render y determinar cuántos items caben por página
  #
  # Ejemplo de uso:
  #   resultado = Dte::ClasificadorItems.call(items: items_array, archivo: '/tmp/calc.pdf')
  #   items_paginados = resultado[:items]
  #   paginas = resultado[:paginas]
  #
  class ClasificadorItems
    # Configuración por defecto del área de items en el PDF
    DEFAULT_CONFIG = {
      y_inicial: 500,    # Posición Y inicial (desde arriba)
      alto: 380,         # Altura del área de items
      ancho: 300,        # Ancho del área de items
      margen_item: 5,    # Espacio entre items
      font_size: 10      # Tamaño de fuente
    }.freeze

    attr_reader :items, :archivo, :config

    def initialize(items:, archivo:, config: {})
      @items = items
      @archivo = archivo
      @config = DEFAULT_CONFIG.merge(config)
    end

    # Método de clase para llamada rápida
    def self.call(items:, archivo:, config: {})
      new(items: items, archivo: archivo, config: config).call
    end

    # Ejecuta la clasificación de items en páginas
    #
    # @return [Hash] { items: Array, paginas: Array, total_paginas: Integer }
    def call
      return resultado_vacio if items.empty?

      items_con_pagina = preparar_items
      paginas = []

      generar_pdf(items_con_pagina, paginas)

      {
        items: items_con_pagina,
        paginas: paginas,
        total_paginas: paginas.count
      }
    end

    private

    def resultado_vacio
      { items: [], paginas: [], total_paginas: 0 }
    end

    def preparar_items
      items.map { |item| item.merge(pagina: nil) }
    end

    def generar_pdf(out_items, paginas)
      y_ini = config[:y_inicial]
      alto = config[:alto]
      ancho = config[:ancho]
      y_lim = y_ini - alto
      n = out_items.count - 1

      Prawn::Document.generate(archivo, page_size: 'A4') do |pdf|
        k = 0
        pg = 1
        paginas << crear_pagina(pg)

        while k <= n
          pdf.bounding_box([110, y_ini], width: ancho, height: alto) do
            quiebre = false

            while k <= n && !quiebre
              item = out_items[k]
              pdf.move_down config[:margen_item]

              pdf.indent 10 do
                if pdf.cursor < y_lim
                  pg += 1
                  paginas << crear_pagina(pg)
                  quiebre = true
                end

                texto = "<font size='#{config[:font_size]}'>#{item[:cantidad]} x #{item[:glosa]}"
                pdf.text texto, inline_format: true
              end

              out_items[k][:pagina] = pg
              k += 1
            end

            pdf.stroke_bounds
            pdf.start_new_page if quiebre
          end
        end
      end
    end

    def crear_pagina(numero)
      {
        pagina: numero,
        folio: -1,
        archivo_caf: nil
      }
    end
  end
end

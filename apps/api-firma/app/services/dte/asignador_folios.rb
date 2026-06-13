# frozen_string_literal: true

module Dte
  # Asigna folios del CAF (Código de Autorización de Folios del SII) a cada página
  # de un documento tributario electrónico.
  #
  # Cada página del DTE necesita un folio único y la clave privada (rsask) del CAF
  # que autorizó ese rango, para poder generar el TED (Timbre Electrónico DTE).
  #
  # Ejemplo de uso:
  #   resultado = Dte::AsignadorFolios.call(
  #     paginas: paginas_array,
  #     empresa_id: 1,
  #     tipo_documento: 33
  #   )
  #   paginas_con_folio = resultado[:paginas]
  #   disponibles = resultado[:disponibles]
  #
  class AsignadorFolios
    attr_reader :paginas, :empresa_id, :tipo_documento

    def initialize(paginas:, empresa_id:, tipo_documento:)
      @paginas = paginas
      @empresa_id = empresa_id
      @tipo_documento = tipo_documento  # Código SII, ej: 33 (factura), 39 (boleta)
    end

    def self.call(paginas:, empresa_id:, tipo_documento:)
      new(
        paginas: paginas,
        empresa_id: empresa_id,
        tipo_documento: tipo_documento
      ).call
    end

    # Punto de entrada: valida precondiciones y asigna folios.
    #
    # @return [Hash] {
    #   paginas: Array con :folio, :rsask y :rango_folio_id en cada elemento,
    #   disponibles: true si hubo folios suficientes para todas las páginas,
    #   folios_usados: Array de números de folio asignados,
    #   error: String con el motivo del fallo, o nil si todo OK
    # }
    def call
      return resultado_sin_paginas if paginas.empty?

      # El tipo de documento debe existir en el catálogo (tabla tipo_documentos)
      tipo_doc = obtener_tipo_documento
      return resultado_tipo_no_encontrado unless tipo_doc

      # La empresa debe estar habilitada para emitir ese tipo de documento
      tipo_habilitado = obtener_tipo_habilitado(tipo_doc.id)
      return resultado_no_habilitado unless tipo_habilitado

      asignar_folios_disponibles(tipo_habilitado)
    end

    private

    # Sin páginas no hay nada que asignar; se considera éxito (disponibles: true)
    def resultado_sin_paginas
      {
        paginas: [],
        disponibles: true,
        folios_usados: [],
        error: nil
      }
    end

    def resultado_tipo_no_encontrado
      {
        paginas: paginas,
        disponibles: false,
        folios_usados: [],
        error: "Tipo de documento #{tipo_documento} no encontrado"
      }
    end

    def resultado_no_habilitado
      {
        paginas: paginas,
        disponibles: false,
        folios_usados: [],
        error: "Empresa no habilitada para tipo de documento #{tipo_documento}"
      }
    end

    def obtener_tipo_documento
      TipoDocumento.find_by(codigo: tipo_documento.to_s)
    end

    # Vincula la empresa con un tipo de documento; desde ahí se obtienen los rangos CAF
    def obtener_tipo_habilitado(tipo_doc_id)
      TipoHabilitado.find_by(
        empresa_id: empresa_id,
        tipo_documento_id: tipo_doc_id
      )
    end

    # Recorre los rangos CAF de la empresa (ordenados por folio inicial) y asigna
    # folios libres a cada página hasta cubrir la cantidad requerida.
    #
    # Estrategia: consumir primero los rangos más antiguos (fa ASC) y, dentro de
    # cada rango, los folios de menor número, para mantener secuencia cronológica.
    def asignar_folios_disponibles(tipo_habilitado)
      cantidad_requerida = paginas.count
      saldo = cantidad_requerida          # Folios que aún faltan por asignar
      indice_pagina = 0
      folios_usados = []

      # fa = folio autorizado inicial del rango CAF
      rangos_folio = RangoFolio.where(tipo_habilitado_id: tipo_habilitado.id).order('fa ASC')

      rangos_folio.each do |rango|
        break if saldo <= 0

        folios_disponibles = Folio.where(rango_folio_id: rango.id, disponible: true)
                                  .order('numero ASC')

        next if folios_disponibles.empty?

        # La clave privada del CAF se reutiliza para todos los folios del mismo rango
        archivo_caf = obtener_ruta_caf(rango)

        folios_disponibles.each do |folio|
          break if saldo <= 0

          # Enriquece la página con los datos necesarios para generar el TED
          paginas[indice_pagina][:folio] = folio.numero
          paginas[indice_pagina][:rsask] = archivo_caf       # Firma del timbre electrónico
          paginas[indice_pagina][:rango_folio_id] = rango.id # Referencia al CAF completo (XML)

          folios_usados << folio.numero
          indice_pagina += 1
          saldo -= 1
        end
      end

      {
        paginas: paginas,
        disponibles: saldo <= 0,
        folios_usados: folios_usados,
        error: saldo > 0 ? "Faltan #{saldo} folios disponibles" : nil
      }
    end

    # Obtiene la clave privada RSA (rsask) del CAF almacenada en el rango.
    # Se guarda en BD en lugar de leer el archivo CAF en cada asignación.
    def obtener_ruta_caf(rango)
      rango.rsask
    rescue StandardError => e
      Rails.logger.error("Error obteniendo rsask del CAF: #{e.message}")
      nil
    end
  end
end

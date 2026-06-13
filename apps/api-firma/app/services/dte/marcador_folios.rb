# frozen_string_literal: true

module Dte
  # Marca folios CAF como usados tras una emisión exitosa.
  class MarcadorFolios
    def self.call(**params)
      new(**params).call
    end

    def initialize(empresa_id:, tipo_documento:, folios_numeros:, paginas:)
      @empresa_id = empresa_id
      @tipo_documento = tipo_documento
      @folios_numeros = folios_numeros
      @paginas = paginas
    end

    def call
      tipo_habilitado = obtener_tipo_habilitado

      ActiveRecord::Base.transaction do
        folios_numeros.each do |numero|
          folio = Folio.disponibles.find_by!(
            tipo_habilitado_id: tipo_habilitado.id,
            numero: numero
          )
          folio.usar!
        end

        actualizar_fecha_uso_rangos
      end

      { success: true, folios_marcados: folios_numeros }
    rescue ActiveRecord::RecordNotFound => e
      { success: false, error: "Folio no disponible para marcar como usado: #{e.message}" }
    end

    private

    attr_reader :empresa_id, :tipo_documento, :folios_numeros, :paginas

    def obtener_tipo_habilitado
      tipo_doc = TipoDocumento.find_by!(codigo: tipo_documento.to_s)
      TipoHabilitado.find_by!(empresa_id: empresa_id, tipo_documento_id: tipo_doc.id)
    end

    def actualizar_fecha_uso_rangos
      rango_ids = paginas.filter_map { |pag| pag[:rango_folio_id] }.uniq
      RangoFolio.where(id: rango_ids).update_all(fecha_uso: Time.current)
    end
  end
end

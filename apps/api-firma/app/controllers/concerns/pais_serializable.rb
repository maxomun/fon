# frozen_string_literal: true

module PaisSerializable
  extend ActiveSupport::Concern

  private

  def pais_payload(pais)
    {
      id: pais.id,
      codigo: pais.codigo,
      nombre: pais.nombre,
      activo: pais.activo
    }
  end
end

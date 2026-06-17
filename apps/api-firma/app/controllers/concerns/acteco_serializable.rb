# frozen_string_literal: true

module ActecoSerializable
  extend ActiveSupport::Concern

  private

  def acteco_payload(acteco)
    {
      id: acteco.id,
      codigo: acteco.codigo,
      nombre: acteco.nombre,
      afecto_iva: acteco.afecto_iva,
      grupo_acteco: {
        id: acteco.grupo_acteco.id,
        nombre: acteco.grupo_acteco.nombre
      }
    }
  end
end

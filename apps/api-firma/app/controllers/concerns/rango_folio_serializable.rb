# frozen_string_literal: true

module RangoFolioSerializable
  extend ActiveSupport::Concern

  private

  def rango_folio_payload(rango)
    tipo_doc = rango.tipo_habilitado&.tipo_documento

    {
      id: rango.id,
      empresa_id: rango.empresa_id,
      tipo_documento: {
        codigo: rango.td,
        nombre: tipo_doc&.nombre
      },
      rango: rango_numeros_payload(rango),
      folios: folios_stats_payload(rango),
      fecha_autorizacion: rango.fa,
      fecha_subida: rango.fecha_subida,
      fecha_ultimo_uso: rango.fecha_uso,
      subido_por: rango.username,
      archivo: rango.archivo
    }
  end

  def rango_folio_detail_payload(rango)
    proximo_folio = rango.folios.disponibles.order(:numero).first

    rango_folio_payload(rango).merge(
      empresa: {
        id: rango.empresa_id,
        razon_social: rango.empresa&.razon_social,
        rut: rango.empresa&.rut
      },
      folios: folios_stats_payload(rango, detailed: true),
      proximo_folio_disponible: proximo_folio&.numero
    )
  end

  def rango_numeros_payload(rango)
    {
      desde: rango.d,
      hasta: rango.h,
      cantidad: rango.cantidad_folios
    }
  end

  def folios_stats_payload(rango, detailed: false)
    stats = {
      disponibles: rango.folios_disponibles.count,
      usados: rango.folios_usados.count,
      total: rango.folios.count
    }

    if detailed
      stats[:anulados] = rango.folios.anulados.count
      stats[:reservados] = rango.folios.reservados.count
    end

    stats
  end
end

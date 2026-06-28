# frozen_string_literal: true

module EmpresaLogoSerializable
  extend ActiveSupport::Concern

  private

  def logo_payload(empresa)
    if empresa.logo.attached?
      blob = empresa.logo.blob
      {
        disponible: true,
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size,
        url: "/api/v1/empresas/#{empresa.id}/logo"
      }
    else
      { disponible: false }
    end
  end
end

# frozen_string_literal: true

module MailerBrandingHelper
  # Paleta alineada con web-arribo (globals.css), en hex para clientes de correo.
  BRAND = {
    background: '#F4F6F9',
    card: '#FFFFFF',
    text: '#2A3142',
    muted: '#667085',
    primary: '#2B4475',
    primary_hover: '#243A63',
    primary_text: '#F8FAFC',
    header: '#1E2A3B',
    header_muted: '#94A3B8',
    border: '#E2E5EB',
    accent_bg: '#EEF2F8'
  }.freeze

  def mail_brand_color(key)
    BRAND.fetch(key)
  end

  def mail_logo_src
    @logo_src
  end

  def mail_logo_visible?
    mail_logo_src.present?
  end

  def mail_logo_url
    MailerConfig.logo_url
  end

  def mail_font_stack
    "'Inter', Arial, Helvetica, sans-serif"
  end
end

# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { MailerConfig.from_address }
  layout 'mailer'
  helper MailerBrandingHelper
  before_action :prepare_logo_attachment

  private

  def prepare_logo_attachment
    external_url = MailerConfig.logo_url
    if external_url.present?
      @logo_src = external_url
      return
    end

    path = MailerConfig.logo_file_path
    return unless File.exist?(path)

    attachments.inline['facturaon-logo.png'] = File.read(path)
    @logo_src = attachments['facturaon-logo.png'].url
  end
end

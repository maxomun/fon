# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { MailerConfig.from_address }
  layout 'mailer'
end

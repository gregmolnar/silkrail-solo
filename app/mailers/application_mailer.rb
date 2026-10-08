class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "downloads@example.com")
  layout "mailer"
end

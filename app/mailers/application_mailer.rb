class ApplicationMailer < ActionMailer::Base
  default from: "hello@jiki.io"
  layout "mailer"

  private
  # Set the locale for the email based on the recipient's preference
  # Usage in subclasses:
  #   def welcome_email(user)
  #     with_locale(user) do
  #       mail(to: user.email, subject: t('.subject'))
  #     end
  #   end
  def with_locale(user, &)
    I18n.with_locale(user.locale || I18n.default_locale, &)
  end
end

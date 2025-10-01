class WelcomeMailer < ApplicationMailer
  # Sends a welcome email to a new user
  #
  # @param user [User] The user to send the welcome email to
  # @param login_url [String] URL for the user to log in and start learning
  def welcome(user, login_url:)
    with_locale(user) do
      @user = user
      @login_url = login_url

      mail(
        to: user.email,
        subject: t(".subject")
      )
    end
  end
end

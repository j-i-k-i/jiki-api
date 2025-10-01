class User::Bootstrap
  include Mandate

  initialize_with :user

  def call
    # Queue welcome email to be sent asynchronously
    User::SendWelcomeEmail.defer(user.id)

    # Future: Add other bootstrap operations here as needed:
    # - Award badges
    # - Create auth tokens
    # - Track metrics
  end
end

class SerializeUsers
  include Mandate

  initialize_with :users

  def call
    users.map { |user| SerializeUser.(user) }
  end
end

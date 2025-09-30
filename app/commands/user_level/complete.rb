class UserLevel::Complete
  include Mandate

  initialize_with :user, :level

  def call
    UserLevel::FindOrCreate.(user, level)
  end
end

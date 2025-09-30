class UserLevel::Complete
  include Mandate

  initialize_with :user, :level

  def call
    user_level = UserLevel::FindOrCreate.(user, level)
    user_level.update!(completed_at: Time.current)
    user_level
  end
end

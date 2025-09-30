class UserLevel::Complete
  include Mandate

  initialize_with :user, :level

  def call
    user_level = UserLevel::FindOrCreate.(user, level)
    user_level.update!(current_user_lesson: nil)
    user_level
  end
end

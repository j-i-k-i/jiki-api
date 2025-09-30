class UserLesson::Complete
  include Mandate

  initialize_with :user, :lesson

  def call
    user_lesson = UserLesson::FindOrCreate.(user, lesson)
    user_lesson.update!(completed_at: Time.current)

    user_level = UserLevel::FindOrCreate.(user, lesson.level)
    user_level.update!(current_user_lesson: nil)

    user_lesson
  end
end

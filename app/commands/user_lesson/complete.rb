class UserLesson::Complete
  include Mandate

  initialize_with :user, :lesson

  def call
    user_lesson = UserLesson::Create.(user, lesson)
    user_lesson.update!(completed_at: Time.current)
    user_lesson
  end
end

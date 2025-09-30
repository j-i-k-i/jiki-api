class UserLesson::Create
  include Mandate

  initialize_with :user, :lesson

  def call
    user_lesson = UserLesson.find_or_initialize_by(user: user, lesson: lesson)
    user_lesson.started_at ||= Time.current
    user_lesson.save!

    user_level = UserLevel::Create.(user, lesson.level)
    user_level.update!(current_user_lesson: user_lesson)

    user_lesson
  end
end

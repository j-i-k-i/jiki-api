class UserLesson::FindOrCreate
  include Mandate

  initialize_with :user, :lesson

  def call
    user_lesson = UserLesson.find_create_or_find_by!(user: user, lesson: lesson) do |ul|
      ul.started_at = Time.current
    end

    user_level = UserLevel::FindOrCreate.(user, lesson.level)
    user_level.update!(current_user_lesson: user_lesson)

    user.update!(current_user_lesson: user_lesson)

    user_lesson
  end
end

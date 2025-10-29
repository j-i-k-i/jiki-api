class UserLesson::Complete
  include Mandate

  initialize_with :user, :lesson

  def call
    ActiveRecord::Base.transaction do
      user_lesson.update!(completed_at: Time.current)

      user_level.update!(current_user_lesson: nil)

      # Unlock concept if this lesson unlocks one
      Concept::UnlockForUser.(lesson.unlocked_concept, user) if lesson.unlocked_concept
    end

    user_lesson
  end

  memoize
  def user_lesson = UserLesson::FindOrCreate.(user, lesson)

  memoize
  def user_level = UserLevel::FindOrCreate.(user, lesson.level)
end

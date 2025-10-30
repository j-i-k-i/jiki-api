class UserLesson::Complete
  include Mandate

  initialize_with :user, :lesson

  def call
    user_lesson.with_lock do
      # Guard: if already completed, return early (idempotent)
      return user_lesson if user_lesson.completed_at.present?

      ActiveRecord::Base.transaction do
        user_lesson.update!(completed_at: Time.current)

        user_level.update!(current_user_lesson: nil)

        # Unlock concept if this lesson unlocks one
        Concept::UnlockForUser.(lesson.unlocked_concept, user) if lesson.unlocked_concept

        # Unlock project if this lesson unlocks one
        UserProject::Create.(user, lesson.unlocked_project) if lesson.unlocked_project
      end
    end

    user_lesson
  end

  memoize
  def user_lesson = UserLesson::FindOrCreate.(user, lesson)

  memoize
  def user_level = UserLevel::FindOrCreate.(user, lesson.level)
end

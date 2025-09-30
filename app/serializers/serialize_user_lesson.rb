class SerializeUserLesson
  include Mandate

  initialize_with user_lesson: nil, user_lesson_data: nil

  def call
    raise ArgumentError, "Either user_lesson or user_lesson_data must be provided" if user_lesson.nil? && user_lesson_data.nil?

    {
      lesson_slug: lesson_slug,
      status: status
    }
  end

  private
  def lesson_slug
    user_lesson_data ? user_lesson_data[:lesson_slug] : user_lesson.lesson.slug
  end

  def status
    completed_at = user_lesson_data ? user_lesson_data[:completed_at] : user_lesson.completed_at
    completed_at.present? ? "completed" : "started"
  end
end

class SerializeUserLevels
  include Mandate

  initialize_with :user_levels

  def call
    # Group data from single optimized query by level
    grouped = results.group_by { |row| row[:level_slug] }

    # Serialize each level with its lessons
    grouped.map do |level_slug, rows|
      {
        level_slug: level_slug,
        user_lessons: rows.map do |row|
          {
            lesson_slug: row[:lesson_slug],
            status: row[:completed_at].present? ? "completed" : "started"
          }
        end
      }
    end
  end

  private
  memoize
  def results
    results = user_levels.
      joins(:level).
      joins(level: { lessons: :user_lessons }).
      where("user_lessons.user_id = user_levels.user_id").
      order("levels.position, lessons.position").
      pluck(
        "levels.slug",
        "lessons.slug",
        "user_lessons.completed_at"
      )

    # Map pluck results (arrays) to hashes for easier access
    results.map do |level_slug, lesson_slug, completed_at|
      {
        level_slug: level_slug,
        lesson_slug: lesson_slug,
        completed_at: completed_at
      }
    end
  end
end

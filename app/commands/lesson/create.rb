class Lesson::Create
  include Mandate

  initialize_with :level, :attributes

  def call
    # Auto-generate slug from title if not provided
    attributes[:slug] ||= attributes[:title]&.parameterize

    # Merge level_id into attributes
    lesson_attributes = attributes.merge(level_id: level.id)

    Lesson.create!(lesson_attributes)
  end
end

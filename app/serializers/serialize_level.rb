class SerializeLevel
  include Mandate

  initialize_with :level

  def call
    {
      slug: level.slug,
      lessons: level.lessons.map { |lesson| { slug: lesson.slug, type: lesson.type } }
    }
  end
end

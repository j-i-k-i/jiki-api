class SerializeLevel
  include Mandate

  initialize_with :level

  def call
    {
      slug: level.slug,
      lessons: SerializeLessons.(level.lessons)
    }
  end
end

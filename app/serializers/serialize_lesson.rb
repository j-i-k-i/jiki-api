class SerializeLesson
  include Mandate

  initialize_with :lesson

  def call
    {
      slug: lesson.slug,
      type: lesson.type,
      data: lesson.data
    }
  end
end

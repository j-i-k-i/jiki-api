class SerializeLessons
  include Mandate

  initialize_with :lessons

  def call
    lessons.map do |lesson|
      SerializeLesson.(lesson)
    end
  end
end

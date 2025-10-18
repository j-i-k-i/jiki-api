class SerializeExerciseSubmission
  include Mandate

  initialize_with :submission

  def call
    {
      uuid: submission.uuid,
      lesson_slug: submission.lesson.slug,
      files: submission.files.map { |file| serialize_file(file) }
    }
  end

  private
  def serialize_file(file)
    {
      filename: file.filename,
      digest: file.digest
    }
  end
end

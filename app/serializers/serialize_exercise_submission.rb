class SerializeExerciseSubmission
  def self.call(submission)
    new(submission).()
  end

  def initialize(submission)
    @submission = submission
  end

  def call
    {
      uuid: submission.uuid,
      lesson_slug: submission.lesson.slug,
      created_at: submission.created_at.iso8601,
      files: submission.files.map { |file| serialize_file(file) }
    }
  end

  private
  attr_reader :submission

  def serialize_file(file)
    {
      filename: file.filename,
      digest: file.digest
    }
  end
end

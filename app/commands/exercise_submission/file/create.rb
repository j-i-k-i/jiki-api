class ExerciseSubmission::File::Create
  include Mandate

  initialize_with :exercise_submission, :filename, :content

  def call
    exercise_submission.files.create!(
      filename:,
      digest:
    ).tap do |file|
      file.content.attach(
        io: StringIO.new(sanitized_content),
        filename:,
        content_type: 'text/plain'
      )
    end
  end

  private
  memoize
  def sanitized_content
    # Convert to UTF-8 encoding, replacing invalid characters
    # This prevents encoding errors when storing/retrieving content
    content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end

  memoize
  def digest = XXhash.xxh64(sanitized_content).to_s
end

class ExerciseSubmission::File::Create
  include Mandate

  initialize_with :exercise_submission, :filename, :content

  def call
    # Sanitize UTF-8 encoding
    sanitized_content = sanitize_utf8(content)

    # Calculate digest
    digest = XXhash.xxh64(sanitized_content).to_s

    # Create file record
    file = exercise_submission.files.create!(
      filename:,
      digest:
    )

    # Attach content to Active Storage
    file.content.attach(
      io: StringIO.new(sanitized_content),
      filename:,
      content_type: 'text/plain'
    )

    file
  end

  private
  def sanitize_utf8(str)
    # Convert to UTF-8 encoding, replacing invalid characters
    # This prevents encoding errors when storing/retrieving content
    str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end

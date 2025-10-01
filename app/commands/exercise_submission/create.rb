class ExerciseSubmission::Create
  include Mandate

  initialize_with :user_lesson, :files

  def call
    # Generate UUID for submission
    uuid = SecureRandom.uuid

    # Create submission
    submission = ExerciseSubmission.create!(
      user_lesson:,
      uuid:
    )

    # Create each file
    files.each do |file_params|
      ExerciseSubmission::File::Create.(
        submission,
        file_params[:filename],
        file_params[:code]
      )
    end

    submission
  end
end

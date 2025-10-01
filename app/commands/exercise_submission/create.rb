class ExerciseSubmission::Create
  include Mandate

  initialize_with :user_lesson, :files

  def call
    ExerciseSubmission.create!(
      user_lesson:,
      uuid:
    ).tap do |submission|
      files.each do |file_params|
        ExerciseSubmission::File::Create.(
          submission,
          file_params[:filename],
          file_params[:code]
        )
      end
    end
  end

  private
  memoize
  def uuid = SecureRandom.uuid
end

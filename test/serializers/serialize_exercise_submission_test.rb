require "test_helper"

class SerializeExerciseSubmissionTest < ActiveSupport::TestCase
  test "returns correct structure" do
    user = create(:user)
    lesson = create(:lesson, slug: "test-lesson")
    user_lesson = create(:user_lesson, user:, lesson:)
    submission = create(:exercise_submission, user_lesson:, uuid: "abc123")

    create(:exercise_submission_file,
      exercise_submission: submission,
      filename: "main.rb",
      digest: "digest1")
    create(:exercise_submission_file,
      exercise_submission: submission,
      filename: "helper.rb",
      digest: "digest2")

    expected = {
      uuid: "abc123",
      lesson_slug: "test-lesson",
      files: [
        { filename: "helper.rb", digest: "digest2" },
        { filename: "main.rb", digest: "digest1" }
      ]
    }

    assert_equal expected, SerializeExerciseSubmission.(submission)
  end

  test "handles submission with no files" do
    user_lesson = create(:user_lesson)
    submission = create(:exercise_submission, user_lesson:)

    result = SerializeExerciseSubmission.(submission)

    assert_empty result[:files]
  end
end

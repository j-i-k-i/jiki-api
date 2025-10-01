require "test_helper"

class ExerciseSubmission::CreateTest < ActiveSupport::TestCase
  test "creates submission with UUID" do
    user_lesson = create(:user_lesson)
    files = [{ filename: "main.rb", code: "puts 'hello'" }]

    submission = ExerciseSubmission::Create.(user_lesson, files)

    assert submission.persisted?
    assert submission.uuid.present?
    assert_equal user_lesson, submission.user_lesson
  end

  test "creates all files via File::Create" do
    user_lesson = create(:user_lesson)
    files = [
      { filename: "main.rb", code: "puts 'hello'" },
      { filename: "helper.rb", code: "def help\nend" }
    ]

    Prosopite.pause do
      submission = ExerciseSubmission::Create.(user_lesson, files)

      assert_equal 2, submission.files.count
      assert_equal ["helper.rb", "main.rb"], submission.files.map(&:filename).sort
    end
  end

  test "associates with user_lesson correctly" do
    user_lesson = create(:user_lesson)
    files = [{ filename: "solution.rb", code: "# solution" }]

    submission = ExerciseSubmission::Create.(user_lesson, files)

    assert_equal user_lesson.user, submission.user
    assert_equal user_lesson.lesson, submission.lesson
  end

  test "each file has correct digest" do
    user_lesson = create(:user_lesson)
    code = "puts 'test'"
    files = [{ filename: "test.rb", code: }]

    submission = ExerciseSubmission::Create.(user_lesson, files)

    file = submission.files.first
    assert_equal XXhash.xxh64(code).to_s, file.digest
  end
end

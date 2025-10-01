require "test_helper"

class ExerciseSubmission::File::CreateTest < ActiveSupport::TestCase
  test "creates file with correct attributes" do
    submission = create(:exercise_submission)
    filename = "solution.rb"
    content = "puts 'Hello, World!'"

    file = ExerciseSubmission::File::Create.(submission, filename, content)

    assert file.persisted?
    assert_equal filename, file.filename
    assert_equal submission, file.exercise_submission
  end

  test "attaches content to Active Storage" do
    submission = create(:exercise_submission)
    content = "def greet\n  'Hello'\nend"

    file = ExerciseSubmission::File::Create.(submission, "greet.rb", content)

    assert file.content.attached?
    assert_equal "greet.rb", file.content.filename.to_s
  end

  test "calculates correct XXHash64 digest" do
    submission = create(:exercise_submission)
    content = "puts 'test'"
    expected_digest = XXhash.xxh64(content).to_s

    file = ExerciseSubmission::File::Create.(submission, "test.rb", content)

    assert_equal expected_digest, file.digest
  end

  test "sanitizes UTF-8 encoding" do
    submission = create(:exercise_submission)
    # String with invalid UTF-8 bytes
    content = "puts 'hello'\x80\x81"

    file = ExerciseSubmission::File::Create.(submission, "test.rb", content)

    # Should not raise an error and should create the file
    assert file.persisted?
    assert file.content.attached?
  end

  test "handles empty content" do
    submission = create(:exercise_submission)
    content = ""

    file = ExerciseSubmission::File::Create.(submission, "empty.rb", content)

    assert file.persisted?
    assert_equal XXhash.xxh64("").to_s, file.digest
  end
end

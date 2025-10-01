require "test_helper"

class SerializeUserLessonTest < ActiveSupport::TestCase
  test "serializes user_lesson with completed status" do
    lesson = create(:lesson, slug: "hello-world", type: "tutorial")
    user_lesson = create(:user_lesson, lesson: lesson, completed_at: Time.current)

    expected = {
      lesson_slug: "hello-world",
      status: "completed",
      data: {}
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson))
  end

  test "serializes user_lesson with started status" do
    lesson = create(:lesson, slug: "hello-world", type: "tutorial")
    user_lesson = create(:user_lesson, lesson: lesson, completed_at: nil)

    expected = {
      lesson_slug: "hello-world",
      status: "started",
      data: {}
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson))
  end

  test "includes last_submission for exercise lesson with submission" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise")
    user_lesson = create(:user_lesson, lesson:)
    submission = create(:exercise_submission, user_lesson:)
    file = create(:exercise_submission_file, exercise_submission: submission, filename: "solution.rb")
    file.content.attach(io: StringIO.new("puts 'Hello'"), filename: "solution.rb")

    result = SerializeUserLesson.(user_lesson)

    assert_equal "hello-world", result[:lesson_slug]
    assert_equal "started", result[:status]
    assert result[:data].key?(:last_submission)
    assert_equal submission.uuid, result[:data][:last_submission][:uuid]
    assert_equal 1, result[:data][:last_submission][:files].length
    assert_equal "solution.rb", result[:data][:last_submission][:files][0][:filename]
    assert_equal "puts 'Hello'", result[:data][:last_submission][:files][0][:content]
  end

  test "includes last_submission as nil for exercise lesson without submission" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise")
    user_lesson = create(:user_lesson, lesson:)

    result = SerializeUserLesson.(user_lesson)

    assert_equal "hello-world", result[:lesson_slug]
    assert_equal "started", result[:status]
    assert result[:data].key?(:last_submission)
    assert_nil result[:data][:last_submission]
  end

  test "does not include last_submission for non-exercise lesson" do
    lesson = create(:lesson, slug: "hello-world", type: "tutorial")
    user_lesson = create(:user_lesson, lesson:)

    result = SerializeUserLesson.(user_lesson)

    assert_equal "hello-world", result[:lesson_slug]
    assert_equal "started", result[:status]
    assert_empty(result[:data])
  end

  test "includes most recent submission when multiple exist" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise")
    user_lesson = create(:user_lesson, lesson:)

    # Create older submission
    old_submission = create(:exercise_submission, user_lesson:, created_at: 2.days.ago)
    old_file = create(:exercise_submission_file, exercise_submission: old_submission, filename: "old.rb")
    old_file.content.attach(io: StringIO.new("old code"), filename: "old.rb")

    # Create newer submission
    new_submission = create(:exercise_submission, user_lesson:, created_at: 1.day.ago)
    new_file = create(:exercise_submission_file, exercise_submission: new_submission, filename: "new.rb")
    new_file.content.attach(io: StringIO.new("new code"), filename: "new.rb")

    result = SerializeUserLesson.(user_lesson)

    assert_equal new_submission.uuid, result[:data][:last_submission][:uuid]
    assert_equal "new.rb", result[:data][:last_submission][:files][0][:filename]
    assert_equal "new code", result[:data][:last_submission][:files][0][:content]
  end

  test "serializes multiple files in submission" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise")
    user_lesson = create(:user_lesson, lesson:)
    submission = create(:exercise_submission, user_lesson:)

    file1 = create(:exercise_submission_file, exercise_submission: submission, filename: "main.rb")
    file1.content.attach(io: StringIO.new("main code"), filename: "main.rb")

    file2 = create(:exercise_submission_file, exercise_submission: submission, filename: "helper.rb")
    file2.content.attach(io: StringIO.new("helper code"), filename: "helper.rb")

    result = SerializeUserLesson.(user_lesson)

    assert_equal 2, result[:data][:last_submission][:files].length
    assert_equal "helper.rb", result[:data][:last_submission][:files][0][:filename]
    assert_equal "helper code", result[:data][:last_submission][:files][0][:content]
    assert_equal "main.rb", result[:data][:last_submission][:files][1][:filename]
    assert_equal "main code", result[:data][:last_submission][:files][1][:content]
  end
end

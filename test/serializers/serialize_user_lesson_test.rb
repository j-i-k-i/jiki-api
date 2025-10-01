require "test_helper"

class SerializeUserLessonTest < ActiveSupport::TestCase
  test "raises error when neither user_lesson nor user_lesson_data provided" do
    error = assert_raises ArgumentError do
      SerializeUserLesson.()
    end

    assert_equal "Either user_lesson or user_lesson_data must be provided", error.message
  end

  test "serializes user_lesson model with completed status" do
    lesson = create(:lesson, slug: "hello-world")
    user_lesson = create(:user_lesson, lesson: lesson, completed_at: Time.current)

    expected = {
      lesson_slug: "hello-world",
      status: "completed"
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson: user_lesson))
  end

  test "serializes user_lesson model with started status" do
    lesson = create(:lesson, slug: "hello-world")
    user_lesson = create(:user_lesson, lesson: lesson, completed_at: nil)

    expected = {
      lesson_slug: "hello-world",
      status: "started"
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson: user_lesson))
  end

  test "serializes user_lesson_data hash with completed status" do
    expected = {
      lesson_slug: "hello-world",
      status: "completed"
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson_data: { lesson_slug: "hello-world", completed_at: Time.current }))
  end

  test "serializes user_lesson_data hash with started status" do
    expected = {
      lesson_slug: "hello-world",
      status: "started"
    }

    assert_equal(expected, SerializeUserLesson.(user_lesson_data: { lesson_slug: "hello-world", completed_at: nil }))
  end
end

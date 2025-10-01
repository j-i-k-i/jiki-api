require "test_helper"

class SerializeLessonTest < ActiveSupport::TestCase
  test "serializes lesson with all fields" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise", data: { slug: "basic-movement" })

    expected = {
      slug: "hello-world",
      type: "exercise",
      data: { slug: "basic-movement" }
    }

    assert_equal(expected, SerializeLesson.(lesson))
  end

  test "serializes complex data hash" do
    lesson = create(:lesson, slug: "test", type: "tutorial", data: { slug: "test-exercise", difficulty: "easy", points: 10 })

    expected = {
      slug: "test",
      type: "tutorial",
      data: { slug: "test-exercise", difficulty: "easy", points: 10 }
    }

    assert_equal(expected, SerializeLesson.(lesson))
  end
end

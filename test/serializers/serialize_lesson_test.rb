require "test_helper"

class SerializeLessonTest < ActiveSupport::TestCase
  test "serializes lesson with all fields" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise", data: { slug: "basic-movement" })

    assert_equal({
      slug: "hello-world",
      type: "exercise",
      data: { slug: "basic-movement" }
    }, SerializeLesson.(lesson))
  end

  test "serializes complex data hash" do
    lesson = create(:lesson, slug: "test", type: "tutorial", data: { slug: "test-exercise", difficulty: "easy", points: 10 })

    assert_equal({
      slug: "test",
      type: "tutorial",
      data: { slug: "test-exercise", difficulty: "easy", points: 10 }
    }, SerializeLesson.(lesson))
  end
end

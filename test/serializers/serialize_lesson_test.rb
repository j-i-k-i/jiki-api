require "test_helper"

class SerializeLessonTest < ActiveSupport::TestCase
  test "basic serialization" do
    lesson = create(:lesson, slug: "hello-world", type: "exercise", data: { slug: "basic-movement" })

    expected = {
      slug: "hello-world",
      type: "exercise",
      data: { slug: "basic-movement" }
    }

    assert_equal expected, SerializeLesson.(lesson)
  end

  test "serializes all required fields" do
    lesson = create(:lesson)
    result = SerializeLesson.(lesson)

    assert result.key?(:slug)
    assert result.key?(:type)
    assert result.key?(:data)
  end

  test "serializes data as hash" do
    data = { slug: "test-exercise", difficulty: "easy" }
    lesson = create(:lesson, data: data)
    result = SerializeLesson.(lesson)

    assert_equal data, result[:data]
  end
end

require "test_helper"

class SerializeLessonsTest < ActiveSupport::TestCase
  test "serializes multiple lessons" do
    level = create(:level)
    lesson1 = create(:lesson, level: level, slug: "lesson-1", type: "exercise", data: { slug: "ex-1" })
    lesson2 = create(:lesson, level: level, slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" })

    result = SerializeLessons.([lesson1, lesson2])

    assert_equal 2, result.length
    assert_equal "lesson-1", result[0][:slug]
    assert_equal "lesson-2", result[1][:slug]
  end

  test "returns empty array for no lessons" do
    result = SerializeLessons.([])

    assert_empty result
  end

  test "each lesson is serialized with SerializeLesson" do
    lesson = create(:lesson)
    result = SerializeLessons.([lesson])

    assert_equal 1, result.length
    assert_equal SerializeLesson.(lesson), result[0]
  end
end

require "test_helper"

class SerializeLessonsTest < ActiveSupport::TestCase
  test "serializes multiple lessons" do
    level = create(:level)
    lesson1 = create(:lesson, level: level, slug: "lesson-1", type: "exercise", data: { slug: "ex-1" })
    lesson2 = create(:lesson, level: level, slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" })

    expected = [
      { slug: "lesson-1", type: "exercise", data: { slug: "ex-1" } },
      { slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" } }
    ]

    assert_equal(expected, SerializeLessons.([lesson1, lesson2]))
  end

  test "returns empty array for no lessons" do
    assert_empty SerializeLessons.([])
  end

  test "serializes single lesson" do
    lesson = create(:lesson, slug: "solo", type: "exercise", data: { slug: "test" })

    expected = [
      { slug: "solo", type: "exercise", data: { slug: "test" } }
    ]

    assert_equal(expected, SerializeLessons.([lesson]))
  end
end

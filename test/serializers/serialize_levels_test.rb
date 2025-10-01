require "test_helper"

class SerializeLevelsTest < ActiveSupport::TestCase
  test "serializes multiple levels with lessons" do
    level1 = create(:level, slug: "level-1")
    level2 = create(:level, slug: "level-2")
    create(:lesson, level: level1, slug: "l1", type: "exercise", data: { slug: "ex1" })
    create(:lesson, level: level2, slug: "l2", type: "tutorial", data: { slug: "ex2" })

    expected = [
      {
        slug: "level-1",
        lessons: [
          { slug: "l1", type: "exercise", data: { slug: "ex1" } }
        ]
      },
      {
        slug: "level-2",
        lessons: [
          { slug: "l2", type: "tutorial", data: { slug: "ex2" } }
        ]
      }
    ]

    assert_equal(expected, SerializeLevels.([level1, level2]))
  end

  test "returns empty array for no levels" do
    assert_empty SerializeLevels.([])
  end

  test "serializes single level" do
    level = create(:level, slug: "solo")
    create(:lesson, level: level, slug: "lesson-solo", type: "exercise", data: { slug: "test" })

    expected = [
      {
        slug: "solo",
        lessons: [
          { slug: "lesson-solo", type: "exercise", data: { slug: "test" } }
        ]
      }
    ]
    assert_equal(expected, SerializeLevels.([level]))
  end
end

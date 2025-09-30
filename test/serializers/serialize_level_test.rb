require "test_helper"

class SerializeLevelTest < ActiveSupport::TestCase
  test "serializes level with lessons" do
    level = create(:level, slug: "level-1")
    create(:lesson, level: level, slug: "lesson-1", type: "exercise", data: { slug: "ex-1" })
    create(:lesson, level: level, slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" })

    assert_equal({
      slug: "level-1",
      lessons: [
        { slug: "lesson-1", type: "exercise", data: { slug: "ex-1" } },
        { slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" } }
      ]
    }, SerializeLevel.(level))
  end

  test "serializes level with no lessons" do
    level = create(:level, slug: "empty-level")

    assert_equal({
      slug: "empty-level",
      lessons: []
    }, SerializeLevel.(level))
  end
end

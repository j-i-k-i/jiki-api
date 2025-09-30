require "test_helper"

class SerializeLevelTest < ActiveSupport::TestCase
  test "basic serialization" do
    level = create(:level, slug: "level-1")
    create(:lesson, level: level, slug: "lesson-1", type: "exercise", data: { slug: "ex-1" })
    create(:lesson, level: level, slug: "lesson-2", type: "tutorial", data: { slug: "ex-2" })

    result = SerializeLevel.(level)

    assert_equal "level-1", result[:slug]
    assert_equal 2, result[:lessons].length
    assert_equal "lesson-1", result[:lessons][0][:slug]
    assert_equal "lesson-2", result[:lessons][1][:slug]
  end

  test "serializes level with no lessons" do
    level = create(:level, slug: "empty-level")

    result = SerializeLevel.(level)

    assert_equal "empty-level", result[:slug]
    assert_empty result[:lessons]
  end

  test "serializes all required fields" do
    level = create(:level)
    result = SerializeLevel.(level)

    assert result.key?(:slug)
    assert result.key?(:lessons)
  end

  test "lessons are serialized with SerializeLessons" do
    level = create(:level)
    create(:lesson, level: level)

    result = SerializeLevel.(level)

    assert_equal SerializeLessons.(level.lessons), result[:lessons]
  end
end

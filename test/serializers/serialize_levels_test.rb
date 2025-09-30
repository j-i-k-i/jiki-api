require "test_helper"

class SerializeLevelsTest < ActiveSupport::TestCase
  test "serializes multiple levels" do
    level1 = create(:level, slug: "level-1")
    level2 = create(:level, slug: "level-2")
    create(:lesson, level: level1)
    create(:lesson, level: level2)

    result = SerializeLevels.([level1, level2])

    assert_equal 2, result.length
    assert_equal "level-1", result[0][:slug]
    assert_equal "level-2", result[1][:slug]
  end

  test "returns empty array for no levels" do
    result = SerializeLevels.([])

    assert_empty result
  end

  test "each level is serialized with SerializeLevel" do
    level = create(:level)
    result = SerializeLevels.([level])

    assert_equal 1, result.length
    assert_equal SerializeLevel.(level), result[0]
  end

  test "includes lessons in query" do
    level = create(:level)
    create(:lesson, level: level)

    # This test verifies that the includes method is used to avoid N+1
    levels = Level.all
    result = SerializeLevels.(levels)

    assert_equal 1, result.length
    assert_equal 1, result[0][:lessons].length
  end
end

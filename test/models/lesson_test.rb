require "test_helper"

class LessonTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:lesson).valid?
  end

  test "auto-increments position within level" do
    level = create(:level)
    lesson1 = create(:lesson, level:)
    lesson2 = create(:lesson, level:)

    assert_equal 1, lesson1.position
    assert_equal 2, lesson2.position
  end

  test "requires unique slug" do
    create(:lesson, slug: "first-function")
    duplicate = build(:lesson, slug: "first-function")

    refute duplicate.valid?
  end

  test "position unique within level" do
    level1 = create(:level)
    level2 = create(:level)

    lesson1 = create(:lesson, level: level1, position: 1)
    lesson2 = create(:lesson, level: level2, position: 1) # Should be valid - different level

    assert lesson1.valid?
    assert lesson2.valid?
    assert_equal 1, lesson1.position
    assert_equal 1, lesson2.position
  end
end

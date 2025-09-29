require "test_helper"

class LevelTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:level).valid?
  end

  test "auto-increments position" do
    level1 = create(:level)
    level2 = create(:level)

    assert_equal 1, level1.position
    assert_equal 2, level2.position
  end

  test "requires unique slug" do
    create(:level, slug: "fundamentals")
    duplicate = build(:level, slug: "fundamentals")

    refute duplicate.valid?
  end
end

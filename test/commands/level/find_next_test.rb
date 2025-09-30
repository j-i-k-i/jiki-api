require "test_helper"

class Level::FindNextTest < ActiveSupport::TestCase
  test "returns the next level by position" do
    level1 = create(:level, position: 1)
    level2 = create(:level, position: 2)
    create(:level, position: 3)

    assert_equal level2, Level::FindNext.(level1)
  end

  test "handles gaps in position numbers" do
    level1 = create(:level, position: 1)
    level5 = create(:level, position: 5)
    create(:level, position: 10)

    assert_equal level5, Level::FindNext.(level1)
  end

  test "returns nil when there is no next level" do
    level = create(:level, position: 100)

    assert_nil Level::FindNext.(level)
  end

  test "returns the correct next level when multiple levels exist" do
    create(:level, position: 1)
    level2 = create(:level, position: 2)
    level3 = create(:level, position: 3)
    create(:level, position: 4)

    assert_equal level3, Level::FindNext.(level2)
  end
end

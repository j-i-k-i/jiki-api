require "test_helper"

class UserLevelTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:user_level).valid?
  end

  test "unique user and level combination" do
    user = create(:user)
    level = create(:level)

    create(:user_level, user:, level:)
    duplicate = build(:user_level, user:, level:)

    refute duplicate.valid?
  end
end

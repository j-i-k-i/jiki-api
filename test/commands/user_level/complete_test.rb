require "test_helper"

class UserLevel::CompleteTest < ActiveSupport::TestCase
  test "finds or creates user_level" do
    user = create(:user)
    level = create(:level)

    result = UserLevel::Complete.(user, level)

    assert result.persisted?
    assert_equal user.id, result.user_id
    assert_equal level.id, result.level_id
  end

  test "returns existing user_level if it exists" do
    user = create(:user)
    level = create(:level)
    user_level = create(:user_level, user: user, level: level)

    result = UserLevel::Complete.(user, level)

    assert_equal user_level.id, result.id
  end

  test "delegates to UserLevel::FindOrCreate for find or create logic" do
    user = create(:user)
    level = create(:level)
    user_level = create(:user_level, user: user, level: level)

    UserLevel::FindOrCreate.expects(:call).with(user, level).returns(user_level)

    UserLevel::Complete.(user, level)
  end

  test "returns the user_level" do
    user = create(:user)
    level = create(:level)

    result = UserLevel::Complete.(user, level)

    assert_instance_of UserLevel, result
  end
end

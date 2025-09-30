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

  test "sets completed_at to current time" do
    user = create(:user)
    level = create(:level)

    time_before = Time.current
    user_level = UserLevel::Complete.(user, level)
    time_after = Time.current

    assert user_level.completed_at >= time_before
    assert user_level.completed_at <= time_after
  end

  test "updates completed_at on already completed level" do
    user = create(:user)
    level = create(:level)
    user_level = create(:user_level, user: user, level: level, completed_at: 1.day.ago)
    old_completed_at = user_level.completed_at

    result = UserLevel::Complete.(user, level)

    assert result.completed_at > old_completed_at
  end

  test "preserves started_at when completing" do
    user = create(:user)
    level = create(:level)
    started_time = 2.days.ago
    create(:user_level, user: user, level: level, started_at: started_time)

    result = UserLevel::Complete.(user, level)

    assert_equal started_time.to_i, result.started_at.to_i
  end
end

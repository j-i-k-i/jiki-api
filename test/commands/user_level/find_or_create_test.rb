require "test_helper"

class UserLevel::FindOrCreateTest < ActiveSupport::TestCase
  test "creates user_level" do
    user = create(:user)
    level = create(:level)

    user_level = UserLevel::FindOrCreate.(user, level)

    assert user_level.persisted?
    assert_equal user.id, user_level.user_id
    assert_equal level.id, user_level.level_id
  end

  test "returns existing user_level on duplicate" do
    user = create(:user)
    level = create(:level)

    user_level1 = UserLevel::FindOrCreate.(user, level)
    user_level2 = UserLevel::FindOrCreate.(user, level)

    assert_equal user_level1.id, user_level2.id
  end

  test "is idempotent" do
    user = create(:user)
    level = create(:level)

    result_one = UserLevel::FindOrCreate.(user, level)
    result_two = UserLevel::FindOrCreate.(user, level)

    assert_equal result_one.id, result_two.id
  end

  test "allows different users to start same level" do
    user1 = create(:user)
    user2 = create(:user)
    level = create(:level)

    user_level1 = UserLevel::FindOrCreate.(user1, level)
    user_level2 = UserLevel::FindOrCreate.(user2, level)

    refute_equal user_level1.id, user_level2.id
    assert_equal level.id, user_level1.level_id
    assert_equal level.id, user_level2.level_id
  end

  test "allows same user to start different levels" do
    user = create(:user)
    level1 = create(:level)
    level2 = create(:level, slug: "different-level")

    user_level1 = UserLevel::FindOrCreate.(user, level1)
    user_level2 = UserLevel::FindOrCreate.(user, level2)

    refute_equal user_level1.id, user_level2.id
    assert_equal user.id, user_level1.user_id
    assert_equal user.id, user_level2.user_id
  end

  test "initializes with nil current_user_lesson" do
    user = create(:user)
    level = create(:level)

    user_level = UserLevel::FindOrCreate.(user, level)

    assert_nil user_level.current_user_lesson_id
  end

  test "sets started_at on creation" do
    user = create(:user)
    level = create(:level)

    time_before = Time.current
    user_level = UserLevel::FindOrCreate.(user, level)
    time_after = Time.current

    assert user_level.started_at >= time_before
    assert user_level.started_at <= time_after
  end

  test "does not overwrite started_at on existing records" do
    user = create(:user)
    level = create(:level)
    original_time = 2.days.ago

    # Create with specific started_at
    user_level = UserLevel.create!(user: user, level: level, started_at: original_time)

    # Call command again
    result = UserLevel::FindOrCreate.(user, level)

    assert_equal user_level.id, result.id
    assert_equal original_time.to_i, result.started_at.to_i
  end

  test "initializes with nil completed_at" do
    user = create(:user)
    level = create(:level)

    user_level = UserLevel::FindOrCreate.(user, level)

    assert_nil user_level.completed_at
  end
end

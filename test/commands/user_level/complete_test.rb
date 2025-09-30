require "test_helper"

class UserLevel::CompleteTest < ActiveSupport::TestCase
  test "completes existing user_level by setting current_user_lesson to nil" do
    user = create(:user)
    level = create(:level)
    lesson = create(:lesson, level: level)
    user_lesson = create(:user_lesson, user: user, lesson: lesson)
    user_level = create(:user_level, user: user, level: level, current_user_lesson: user_lesson)

    result = UserLevel::Complete.(user, level)

    assert_equal user_level.id, result.id
    assert_nil result.current_user_lesson_id
  end

  test "creates and completes user_level if it doesn't exist" do
    user = create(:user)
    level = create(:level)

    user_level = UserLevel::Complete.(user, level)

    assert user_level.persisted?
    assert_equal user.id, user_level.user_id
    assert_equal level.id, user_level.level_id
    assert_nil user_level.current_user_lesson_id
  end

  test "sets current_user_lesson to nil even if already nil" do
    user = create(:user)
    level = create(:level)
    user_level = create(:user_level, user: user, level: level, current_user_lesson: nil)

    result = UserLevel::Complete.(user, level)

    assert_equal user_level.id, result.id
    assert_nil result.current_user_lesson_id
  end

  test "delegates to UserLevel::FindOrCreate for find or create logic" do
    user = create(:user)
    level = create(:level)
    user_level = create(:user_level, user: user, level: level)

    UserLevel::FindOrCreate.expects(:call).with(user, level).returns(user_level)

    UserLevel::Complete.(user, level)
  end

  test "returns the completed user_level" do
    user = create(:user)
    level = create(:level)

    result = UserLevel::Complete.(user, level)

    assert_instance_of UserLevel, result
    assert_nil result.current_user_lesson_id
  end
end

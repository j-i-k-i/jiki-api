require "test_helper"

class UserLesson::CreateTest < ActiveSupport::TestCase
  test "creates user_lesson with started_at set" do
    user = create(:user)
    lesson = create(:lesson)

    user_lesson = UserLesson::Create.(user, lesson)

    assert user_lesson.persisted?
    assert_equal user.id, user_lesson.user_id
    assert_equal lesson.id, user_lesson.lesson_id
    assert user_lesson.started_at.present?
    assert_nil user_lesson.completed_at
  end

  test "sets started_at to current time" do
    user = create(:user)
    lesson = create(:lesson)

    time_before = Time.current
    user_lesson = UserLesson::Create.(user, lesson)
    time_after = Time.current

    assert user_lesson.started_at >= time_before
    assert user_lesson.started_at <= time_after
  end

  test "returns existing user_lesson on duplicate" do
    user = create(:user)
    lesson = create(:lesson)

    user_lesson1 = UserLesson::Create.(user, lesson)
    user_lesson2 = UserLesson::Create.(user, lesson)

    assert_equal user_lesson1.id, user_lesson2.id
  end

  test "is idempotent" do
    user = create(:user)
    lesson = create(:lesson)

    result_one = UserLesson::Create.(user, lesson)
    result_two = UserLesson::Create.(user, lesson)

    assert_equal result_one.id, result_two.id
  end

  test "does not overwrite started_at on existing records" do
    user = create(:user)
    lesson = create(:lesson)
    original_time = 2.days.ago

    # Create with specific started_at
    user_lesson = UserLesson.create!(user: user, lesson: lesson, started_at: original_time)

    # Call command again
    result = UserLesson::Create.(user, lesson)

    assert_equal user_lesson.id, result.id
    assert_equal original_time.to_i, result.started_at.to_i
  end

  test "allows different users to start same lesson" do
    user1 = create(:user)
    user2 = create(:user)
    lesson = create(:lesson)

    user_lesson1 = UserLesson::Create.(user1, lesson)
    user_lesson2 = UserLesson::Create.(user2, lesson)

    refute_equal user_lesson1.id, user_lesson2.id
    assert_equal lesson.id, user_lesson1.lesson_id
    assert_equal lesson.id, user_lesson2.lesson_id
  end

  test "allows same user to start different lessons" do
    user = create(:user)
    lesson1 = create(:lesson)
    lesson2 = create(:lesson, slug: "different-lesson")

    user_lesson1 = UserLesson::Create.(user, lesson1)
    user_lesson2 = UserLesson::Create.(user, lesson2)

    refute_equal user_lesson1.id, user_lesson2.id
    assert_equal user.id, user_lesson1.user_id
    assert_equal user.id, user_lesson2.user_id
  end
end

require "test_helper"

class UserLesson::FindOrCreateTest < ActiveSupport::TestCase
  test "creates user_lesson with started_at set" do
    user = create(:user)
    lesson = create(:lesson)

    user_lesson = UserLesson::FindOrCreate.(user, lesson)

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
    user_lesson = UserLesson::FindOrCreate.(user, lesson)
    time_after = Time.current

    assert user_lesson.started_at >= time_before
    assert user_lesson.started_at <= time_after
  end

  test "returns existing user_lesson on duplicate" do
    user = create(:user)
    lesson = create(:lesson)

    user_lesson1 = UserLesson::FindOrCreate.(user, lesson)
    user_lesson2 = UserLesson::FindOrCreate.(user, lesson)

    assert_equal user_lesson1.id, user_lesson2.id
  end

  test "is idempotent" do
    user = create(:user)
    lesson = create(:lesson)

    result_one = UserLesson::FindOrCreate.(user, lesson)
    result_two = UserLesson::FindOrCreate.(user, lesson)

    assert_equal result_one.id, result_two.id
  end

  test "does not overwrite started_at on existing records" do
    user = create(:user)
    lesson = create(:lesson)
    original_time = 2.days.ago

    # Create with specific started_at
    user_lesson = UserLesson.create!(user: user, lesson: lesson, started_at: original_time)

    # Call command again
    result = UserLesson::FindOrCreate.(user, lesson)

    assert_equal user_lesson.id, result.id
    assert_equal original_time.to_i, result.started_at.to_i
  end

  test "allows different users to start same lesson" do
    user1 = create(:user)
    user2 = create(:user)
    lesson = create(:lesson)

    user_lesson1 = UserLesson::FindOrCreate.(user1, lesson)
    user_lesson2 = UserLesson::FindOrCreate.(user2, lesson)

    refute_equal user_lesson1.id, user_lesson2.id
    assert_equal lesson.id, user_lesson1.lesson_id
    assert_equal lesson.id, user_lesson2.lesson_id
  end

  test "allows same user to start different lessons" do
    user = create(:user)
    lesson1 = create(:lesson)
    lesson2 = create(:lesson, slug: "different-lesson")

    user_lesson1 = UserLesson::FindOrCreate.(user, lesson1)
    user_lesson2 = UserLesson::FindOrCreate.(user, lesson2)

    refute_equal user_lesson1.id, user_lesson2.id
    assert_equal user.id, user_lesson1.user_id
    assert_equal user.id, user_lesson2.user_id
  end

  test "creates user_level for the lesson's level" do
    user = create(:user)
    lesson = create(:lesson)

    UserLesson::FindOrCreate.(user, lesson)

    user_level = UserLevel.find_by(user: user, level: lesson.level)
    assert user_level.present?
    assert_equal lesson.level.id, user_level.level_id
  end

  test "sets current_user_lesson on user_level" do
    user = create(:user)
    lesson = create(:lesson)

    user_lesson = UserLesson::FindOrCreate.(user, lesson)

    user_level = UserLevel.find_by(user: user, level: lesson.level)
    assert_equal user_lesson.id, user_level.current_user_lesson_id
  end

  test "updates current_user_lesson when starting different lesson in same level" do
    user = create(:user)
    level = create(:level)
    lesson1 = create(:lesson, level: level, slug: "first-lesson")
    lesson2 = create(:lesson, level: level, slug: "second-lesson")

    user_lesson1 = UserLesson::FindOrCreate.(user, lesson1)
    user_level = UserLevel.find_by(user: user, level: level)
    assert_equal user_lesson1.id, user_level.current_user_lesson_id

    user_lesson2 = UserLesson::FindOrCreate.(user, lesson2)
    user_level.reload
    assert_equal user_lesson2.id, user_level.current_user_lesson_id
  end

  test "reuses existing user_level for lessons in same level" do
    user = create(:user)
    level = create(:level)
    lesson1 = create(:lesson, level: level, slug: "first-lesson")
    lesson2 = create(:lesson, level: level, slug: "second-lesson")

    UserLesson::FindOrCreate.(user, lesson1)
    user_level1 = UserLevel.find_by(user: user, level: level)

    UserLesson::FindOrCreate.(user, lesson2)
    user_level2 = UserLevel.find_by(user: user, level: level)

    assert_equal user_level1.id, user_level2.id
  end

  test "sets current_user_level on user" do
    user = create(:user)
    lesson = create(:lesson)

    UserLesson::FindOrCreate.(user, lesson)

    user.reload
    user_level = UserLevel.find_by(user: user, level: lesson.level)
    assert_equal user_level.id, user.current_user_level_id
  end

  test "updates current_user_level when starting lesson in different level" do
    user = create(:user)
    level1 = create(:level, slug: "level-1")
    level2 = create(:level, slug: "level-2")
    lesson1 = create(:lesson, level: level1, slug: "first-lesson")
    lesson2 = create(:lesson, level: level2, slug: "second-lesson")

    UserLesson::FindOrCreate.(user, lesson1)
    user.reload
    user_level1 = UserLevel.find_by(user: user, level: level1)
    assert_equal user_level1.id, user.current_user_level_id

    UserLesson::FindOrCreate.(user, lesson2)
    user.reload
    user_level2 = UserLevel.find_by(user: user, level: level2)
    assert_equal user_level2.id, user.current_user_level_id
  end

  test "initializes user with nil current_user_level" do
    user = create(:user)

    assert_nil user.current_user_level_id
  end
end

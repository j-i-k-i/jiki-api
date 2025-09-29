require "test_helper"

class UserLessonTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:user_lesson).valid?
  end

  test "unique user and lesson combination" do
    user = create(:user)
    lesson = create(:lesson)

    create(:user_lesson, user:, lesson:)
    duplicate = build(:user_lesson, user:, lesson:)

    refute duplicate.valid?
  end
end

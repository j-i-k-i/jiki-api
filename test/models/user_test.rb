require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all attributes" do
    user = build(:user)
    assert user.valid?
  end

  test "invalid without email" do
    user = build(:user, email: nil)
    refute user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    refute user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "invalid with invalid email format" do
    user = build(:user, email: "invalid-email")
    refute user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "invalid without password" do
    user = build(:user, password: nil)
    refute user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "invalid with short password" do
    user = build(:user, password: "short", password_confirmation: "short")
    refute user.valid?
    assert(user.errors[:password].any? { |msg| msg.include?("is too short") })
  end

  test "generates JTI on creation" do
    user = create(:user)
    assert user.jti.present?
    assert_match(/^[a-f0-9-]{36}$/, user.jti) # UUID format
  end

  test "authenticates with correct password" do
    password = "testpassword123"
    user = create(:user, password: password)
    assert user.valid_password?(password)
  end

  test "does not authenticate with incorrect password" do
    user = create(:user, password: "correctpassword")
    refute user.valid_password?("wrongpassword")
  end

  test "name is optional" do
    user = build(:user, name: nil)
    assert user.valid?
  end

  test "locale is required" do
    user = build(:user, locale: nil)
    refute user.valid?
    assert_includes user.errors[:locale], "can't be blank"
  end

  test "locale must be en or hu" do
    user = build(:user, locale: "fr")
    refute user.valid?
    assert_includes user.errors[:locale], "is not included in the list"

    user.locale = "en"
    assert user.valid?

    user.locale = "hu"
    assert user.valid?
  end

  test "JWT revocation strategy included" do
    assert_includes User.included_modules, Devise::JWT::RevocationStrategies::JTIMatcher
  end

  test "deleting user cascades to delete user_lessons and user_levels" do
    user = create(:user)
    level = create(:level)
    lesson = create(:lesson)

    user_level = create(:user_level, user:, level:)
    user_lesson = create(:user_lesson, user:, lesson:)

    user_level_id = user_level.id
    user_lesson_id = user_lesson.id

    user.destroy!

    refute UserLevel.exists?(user_level_id)
    refute UserLesson.exists?(user_lesson_id)
  end

  test "automatically creates data record on user creation" do
    user = create(:user)

    assert user.data.present?
    assert_instance_of User::Data, user.data
    assert user.data.persisted?
  end

  test "data record has empty unlocked_concept_ids by default" do
    user = create(:user)

    assert_empty user.data.unlocked_concept_ids
  end
end

require "test_helper"

class V1::UserLevelsControllerTest < ApplicationControllerTest
  setup do
    setup_user
  end

  # Authentication guards
  guard_incorrect_token! :v1_user_levels_path, method: :get

  test "GET index returns all user_levels with nested user_lessons" do
    level1 = create(:level, slug: "basics", position: 1)
    level2 = create(:level, slug: "advanced", position: 2)

    lesson1 = create(:lesson, level: level1, slug: "lesson-1", position: 1)
    lesson2 = create(:lesson, level: level1, slug: "lesson-2", position: 2)
    lesson3 = create(:lesson, level: level2, slug: "lesson-3", position: 1)

    create(:user_level, user: @current_user, level: level1)
    create(:user_level, user: @current_user, level: level2)

    create(:user_lesson, user: @current_user, lesson: lesson1, completed_at: Time.current)
    create(:user_lesson, user: @current_user, lesson: lesson2, completed_at: nil)
    create(:user_lesson, user: @current_user, lesson: lesson3, completed_at: Time.current)

    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      user_levels: [
        {
          level_slug: "basics",
          user_lessons: [
            { lesson_slug: "lesson-1", status: "completed" },
            { lesson_slug: "lesson-2", status: "started" }
          ]
        },
        {
          level_slug: "advanced",
          user_lessons: [
            { lesson_slug: "lesson-3", status: "completed" }
          ]
        }
      ]
    })
  end

  test "GET index returns empty array when no user_levels exist" do
    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({ user_levels: [] })
  end

  test "GET index only returns current user's user_levels" do
    other_user = create(:user)
    level1 = create(:level, slug: "my-level")
    level2 = create(:level, slug: "other-level")

    lesson1 = create(:lesson, level: level1, slug: "my-lesson")
    lesson2 = create(:lesson, level: level2, slug: "other-lesson")

    create(:user_level, user: @current_user, level: level1)
    create(:user_level, user: other_user, level: level2)

    create(:user_lesson, user: @current_user, lesson: lesson1)
    create(:user_lesson, user: other_user, lesson: lesson2)

    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      user_levels: [
        {
          level_slug: "my-level",
          user_lessons: [
            { lesson_slug: "my-lesson", status: "started" }
          ]
        }
      ]
    })
  end

  test "GET index returns correct JSON structure" do
    level = create(:level)
    lesson = create(:lesson, level: level)
    create(:user_level, user: @current_user, level: level)
    create(:user_lesson, user: @current_user, lesson: lesson)

    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success

    assert_json_structure({
      user_levels: [
        {
          level_slug: String,
          user_lessons: [
            {
              lesson_slug: String,
              status: String
            }
          ]
        }
      ]
    })
  end

  test "GET index uses SerializeUserLevels" do
    Prosopite.finish # Stop scan before creating test data
    user_levels = create_list(:user_level, 2, user: @current_user)
    serialized_data = [{ level_slug: "test" }]

    SerializeUserLevels.expects(:call).with { |arg| arg.to_a == user_levels }.returns(serialized_data)

    Prosopite.scan # Resume scan for the actual request
    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({ user_levels: serialized_data })
  end

  test "GET index maintains level position order" do
    level1 = create(:level, slug: "level-c", position: 3)
    level2 = create(:level, slug: "level-a", position: 1)
    level3 = create(:level, slug: "level-b", position: 2)

    lesson1 = create(:lesson, level: level1, slug: "lesson-c")
    lesson2 = create(:lesson, level: level2, slug: "lesson-a")
    lesson3 = create(:lesson, level: level3, slug: "lesson-b")

    create(:user_level, user: @current_user, level: level1)
    create(:user_level, user: @current_user, level: level2)
    create(:user_level, user: @current_user, level: level3)

    create(:user_lesson, user: @current_user, lesson: lesson1)
    create(:user_lesson, user: @current_user, lesson: lesson2)
    create(:user_lesson, user: @current_user, lesson: lesson3)

    get v1_user_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      user_levels: [
        { level_slug: "level-a", user_lessons: [{ lesson_slug: "lesson-a", status: "started" }] },
        { level_slug: "level-b", user_lessons: [{ lesson_slug: "lesson-b", status: "started" }] },
        { level_slug: "level-c", user_lessons: [{ lesson_slug: "lesson-c", status: "started" }] }
      ]
    })
  end
end

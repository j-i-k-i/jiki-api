require "test_helper"

class V1::UserLessonsControllerTest < ApplicationControllerTest
  setup do
    setup_user
    @lesson = create(:lesson)
  end

  # Authentication guards
  guard_incorrect_token! :v1_user_lesson_path, args: ["solve-a-maze"], method: :get
  guard_incorrect_token! :start_v1_user_lesson_path, args: ["solve-a-maze"], method: :post
  guard_incorrect_token! :complete_v1_user_lesson_path, args: ["solve-a-maze"], method: :patch

  # GET /v1/user_lessons/:slug tests
  test "GET show returns user lesson progress" do
    user_lesson = create(:user_lesson, user: @current_user, lesson: @lesson)
    serialized_data = { lesson_slug: @lesson.slug, status: "started", data: {} }

    SerializeUserLesson.expects(:call).with(user_lesson).returns(serialized_data)

    get v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success
    assert_json_response({ user_lesson: serialized_data })
  end

  test "GET show returns 404 when user_lesson does not exist" do
    get v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "User lesson not found"
      }
    })
  end

  test "GET show returns 404 for non-existent lesson" do
    get v1_user_lesson_path(lesson_slug: "non-existent-slug"),
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    })
  end

  # POST /v1/user_lessons/:slug/start tests
  test "POST start successfully starts a lesson" do
    post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success
    assert_json_response({})
  end

  test "POST start delegates to UserLesson::FindOrCreate command" do
    UserLesson::FindOrCreate.expects(:call).with(@current_user, @lesson)

    post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "POST start returns 404 for non-existent lesson" do
    post start_v1_user_lesson_path(lesson_slug: "non-existent-slug"),
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    })
  end

  test "POST start is idempotent" do
    assert_difference "UserLesson.count", 1 do
      post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success

    assert_no_difference "UserLesson.count" do
      post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  test "POST start creates user_lesson record" do
    assert_difference "UserLesson.count", 1 do
      post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  test "POST start does not create duplicate user_lessons" do
    # First start
    post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    # Second start should not create another record
    assert_no_difference "UserLesson.count" do
      post start_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  # PATCH /v1/user_lessons/:slug/complete tests
  test "PATCH complete successfully completes a lesson" do
    patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success
    assert_json_response({})
  end

  test "PATCH complete delegates to UserLesson::Complete command" do
    UserLesson::Complete.expects(:call).with(@current_user, @lesson)

    patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "PATCH complete returns 404 for non-existent lesson" do
    patch complete_v1_user_lesson_path(lesson_slug: "non-existent-slug"),
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Lesson not found"
      }
    })
  end

  test "PATCH complete is idempotent" do
    assert_difference "UserLesson.count", 1 do
      patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success

    assert_no_difference "UserLesson.count" do
      patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  test "PATCH complete creates user_lesson if not started yet" do
    assert_difference "UserLesson.count", 1 do
      patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  test "PATCH complete does not create duplicate user_lessons" do
    # First completion
    patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
      headers: @headers,
      as: :json

    # Second completion should not create another record
    assert_no_difference "UserLesson.count" do
      patch complete_v1_user_lesson_path(lesson_slug: @lesson.slug),
        headers: @headers,
        as: :json
    end

    assert_response :success
  end

  test "PATCH complete emits events for unlocked concept and project" do
    Prosopite.finish

    concept = create(:concept, slug: "variables", title: "Variables")
    project = create(:project, slug: "calculator", title: "Calculator", description: "Build a calculator")
    lesson = create(:lesson, unlocked_concept: concept, unlocked_project: project)

    patch complete_v1_user_lesson_path(lesson_slug: lesson.slug),
      headers: @headers,
      as: :json

    assert_response :success

    response_json = JSON.parse(response.body, symbolize_names: true)

    # Verify we have two events
    assert_equal 2, response_json[:meta][:events].size

    # Verify concept_unlocked event
    concept_event = response_json[:meta][:events].find { |e| e[:type] == "concept_unlocked" }
    refute_nil concept_event, "Expected concept_unlocked event"
    assert_equal_json SerializeConcept.(concept), concept_event[:data][:concept]

    # Verify project_unlocked event
    project_event = response_json[:meta][:events].find { |e| e[:type] == "project_unlocked" }
    refute_nil project_event, "Expected project_unlocked event"
    assert_equal_json SerializeProject.(project), project_event[:data][:project]
  end
end

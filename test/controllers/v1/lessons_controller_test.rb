require "test_helper"

module V1
  class LessonsControllerTest < ApplicationControllerTest
    setup do
      setup_user
      @lesson = create(:lesson)
    end

    # Authentication guards
    guard_incorrect_token! :start_v1_lesson_path, args: ["solve-a-maze"], method: :post
    guard_incorrect_token! :complete_v1_lesson_path, args: ["solve-a-maze"], method: :patch

    # POST /v1/lessons/:slug/start tests
    test "POST start successfully starts a lesson" do
      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :created

      json = response.parsed_body
      assert json["user_lesson"].present?
      assert_equal @lesson.id, json["user_lesson"]["lesson_id"]
      assert json["user_lesson"]["started_at"].present?
      assert_nil json["user_lesson"]["completed_at"]
    end

    test "POST start delegates to UserLesson::FindOrCreate command" do
      user_lesson = build(:user_lesson, user: @current_user, lesson: @lesson)
      UserLesson::FindOrCreate.expects(:call).with(@current_user, @lesson).returns(user_lesson)

      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :created
    end

    test "POST start returns 404 for non-existent lesson" do
      post start_v1_lesson_path("non-existent-slug"),
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

    test "POST start returns correct JSON structure" do
      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :created

      assert_json_structure({
        user_lesson: {
          id: Integer,
          lesson_id: Integer,
          started_at: String,
          completed_at: NilClass
        }
      })
    end

    test "POST start is idempotent" do
      # First start
      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :created
      first_id = response.parsed_body["user_lesson"]["id"]

      # Second start
      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :created
      second_id = response.parsed_body["user_lesson"]["id"]

      assert_equal first_id, second_id
    end

    test "POST start creates user_lesson record" do
      assert_difference "UserLesson.count", 1 do
        post start_v1_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :created
    end

    test "POST start does not create duplicate user_lessons" do
      # First start
      post start_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      # Second start should not create another record
      assert_no_difference "UserLesson.count" do
        post start_v1_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :created
    end

    # PATCH /v1/lessons/:slug/complete tests
    test "PATCH complete successfully completes a lesson" do
      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :ok

      json = response.parsed_body
      assert json["user_lesson"].present?
      assert_equal @lesson.id, json["user_lesson"]["lesson_id"]
      assert json["user_lesson"]["started_at"].present?
      assert json["user_lesson"]["completed_at"].present?
    end

    test "PATCH complete delegates to UserLesson::Complete command" do
      user_lesson = build(:user_lesson, user: @current_user, lesson: @lesson)
      UserLesson::Complete.expects(:call).with(@current_user, @lesson).returns(user_lesson)

      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :ok
    end

    test "PATCH complete returns 404 for non-existent lesson" do
      patch complete_v1_lesson_path("non-existent-slug"),
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

    test "PATCH complete returns correct JSON structure" do
      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :ok

      assert_json_structure({
        user_lesson: {
          id: Integer,
          lesson_id: Integer,
          started_at: String,
          completed_at: String
        }
      })
    end

    test "PATCH complete is idempotent" do
      # First completion
      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :ok
      first_id = response.parsed_body["user_lesson"]["id"]

      # Second completion
      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :ok
      second_id = response.parsed_body["user_lesson"]["id"]

      assert_equal first_id, second_id
    end

    test "PATCH complete creates user_lesson if not started yet" do
      assert_difference "UserLesson.count", 1 do
        patch complete_v1_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :ok
    end

    test "PATCH complete does not create duplicate user_lessons" do
      # First completion
      patch complete_v1_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      # Second completion should not create another record
      assert_no_difference "UserLesson.count" do
        patch complete_v1_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :ok
    end
  end
end

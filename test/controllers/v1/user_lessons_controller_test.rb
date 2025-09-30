require "test_helper"

module V1
  class UserLessonsControllerTest < ApplicationControllerTest
    setup do
      setup_user
      @lesson = create(:lesson)
    end

    # Authentication guards
    guard_incorrect_token! :start_v1_user_lesson_path, args: ["solve-a-maze"], method: :post
    guard_incorrect_token! :complete_v1_user_lesson_path, args: ["solve-a-maze"], method: :patch

    # POST /v1/user_lessons/:slug/start tests
    test "POST start successfully starts a lesson" do
      post start_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :success
      assert_json_response({})
    end

    test "POST start delegates to UserLesson::FindOrCreate command" do
      UserLesson::FindOrCreate.expects(:call).with(@current_user, @lesson)

      post start_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :success
    end

    test "POST start returns 404 for non-existent lesson" do
      post start_v1_user_lesson_path("non-existent-slug"),
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
        post start_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success

      assert_no_difference "UserLesson.count" do
        post start_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end

    test "POST start creates user_lesson record" do
      assert_difference "UserLesson.count", 1 do
        post start_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end

    test "POST start does not create duplicate user_lessons" do
      # First start
      post start_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      # Second start should not create another record
      assert_no_difference "UserLesson.count" do
        post start_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end

    # PATCH /v1/user_lessons/:slug/complete tests
    test "PATCH complete successfully completes a lesson" do
      patch complete_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :success
      assert_json_response({})
    end

    test "PATCH complete delegates to UserLesson::Complete command" do
      UserLesson::Complete.expects(:call).with(@current_user, @lesson)

      patch complete_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      assert_response :success
    end

    test "PATCH complete returns 404 for non-existent lesson" do
      patch complete_v1_user_lesson_path("non-existent-slug"),
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
        patch complete_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success

      assert_no_difference "UserLesson.count" do
        patch complete_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end

    test "PATCH complete creates user_lesson if not started yet" do
      assert_difference "UserLesson.count", 1 do
        patch complete_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end

    test "PATCH complete does not create duplicate user_lessons" do
      # First completion
      patch complete_v1_user_lesson_path(@lesson.slug),
        headers: @headers,
        as: :json

      # Second completion should not create another record
      assert_no_difference "UserLesson.count" do
        patch complete_v1_user_lesson_path(@lesson.slug),
          headers: @headers,
          as: :json
      end

      assert_response :success
    end
  end
end

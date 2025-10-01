require "test_helper"

module V1
  class LessonsControllerTest < ApplicationControllerTest
    setup do
      setup_user
    end

    # Authentication guards
    guard_incorrect_token! :v1_lesson_path, args: ["test-lesson"], method: :get

    test "GET show returns lesson with data" do
      level = create(:level)
      create(:lesson, level: level, slug: "test-lesson", type: "exercise", data: { slug: "ex1", title: "Test Exercise" })

      get v1_lesson_path(slug: "test-lesson"), headers: @headers, as: :json

      assert_response :success
      assert_json_response({
        lesson: {
          slug: "test-lesson",
          type: "exercise",
          data: { slug: "ex1", title: "Test Exercise" }
        }
      })
    end

    test "GET show returns 404 for non-existent lesson" do
      get v1_lesson_path(slug: "non-existent"), headers: @headers, as: :json

      assert_response :not_found
    end

    test "GET show uses SerializeLesson" do
      Prosopite.finish # Stop scan before creating test data
      level = create(:level)
      lesson = create(:lesson, level: level, slug: "test-lesson")
      serialized_data = { slug: "test", type: "exercise", data: {} }

      SerializeLesson.expects(:call).with(lesson).returns(serialized_data)

      Prosopite.scan # Resume scan for the actual request
      get v1_lesson_path(slug: "test-lesson"), headers: @headers, as: :json

      assert_response :success
      assert_json_response({ lesson: serialized_data })
    end
  end
end

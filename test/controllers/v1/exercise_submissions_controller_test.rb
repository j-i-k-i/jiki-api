require "test_helper"

class V1::ExerciseSubmissionsControllerTest < ApplicationControllerTest
  setup do
    setup_user
    @lesson = create(:lesson)
  end

  guard_incorrect_token! :v1_lesson_exercise_submissions_path, args: ["test-slug"], method: :post

  test "POST create successfully creates submission" do
    files = [
      { filename: "main.rb", code: "puts 'hello'" },
      { filename: "helper.rb", code: "def help\nend" }
    ]

    Prosopite.pause do
      post v1_lesson_exercise_submissions_path(lesson_slug: @lesson.slug),
        params: { submission: { files: } },
        headers: @headers,
        as: :json
    end

    assert_response :created
    assert_json_response({})
  end

  test "POST create finds or creates UserLesson" do
    files = [{ filename: "solution.rb", code: "# code" }]

    UserLesson::FindOrCreate.expects(:call).with(
      @current_user,
      @lesson
    ).returns(create(:user_lesson))

    post v1_lesson_exercise_submissions_path(lesson_slug: @lesson.slug),
      params: { submission: { files: } },
      headers: @headers,
      as: :json

    assert_response :created
  end

  test "POST create calls ExerciseSubmission::Create" do
    user_lesson = create(:user_lesson, user: @current_user, lesson: @lesson)
    files = [{ filename: "test.rb", code: "puts 'test'" }]

    UserLesson::FindOrCreate.stubs(:call).returns(user_lesson)

    ExerciseSubmission::Create.expects(:call).with do |ul, file_params|
      ul == user_lesson &&
        file_params.length == 1 &&
        file_params[0]["filename"] == "test.rb" &&
        file_params[0]["code"] == "puts 'test'"
    end.returns(create(:exercise_submission))

    post v1_lesson_exercise_submissions_path(lesson_slug: @lesson.slug),
      params: { submission: { files: } },
      headers: @headers,
      as: :json

    assert_response :created
  end

  test "POST create handles invalid lesson slug" do
    files = [{ filename: "test.rb", code: "code" }]

    post v1_lesson_exercise_submissions_path(lesson_slug: "nonexistent"),
      params: { submission: { files: } },
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

  test "POST create with multiple files" do
    files = [
      { filename: "file1.rb", code: "code1" },
      { filename: "file2.rb", code: "code2" },
      { filename: "file3.rb", code: "code3" }
    ]

    Prosopite.pause do
      post v1_lesson_exercise_submissions_path(lesson_slug: @lesson.slug),
        params: { submission: { files: } },
        headers: @headers,
        as: :json
    end

    assert_response :created
  end
end

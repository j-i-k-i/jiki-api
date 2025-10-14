require "test_helper"

class V1::Admin::Levels::LessonsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
    @level = create(:level)
  end

  # Authentication and authorization guards
  guard_admin! :v1_admin_level_lessons_path, args: [1], method: :get
  guard_admin! :v1_admin_level_lesson_path, args: [1, 1], method: :patch

  # INDEX tests

  test "GET index returns all lessons for a level" do
    Prosopite.finish
    lesson_1 = create(:lesson, level: @level, title: "Lesson 1", slug: "lesson-1")
    lesson_2 = create(:lesson, level: @level, title: "Lesson 2", slug: "lesson-2")
    # Create lesson in different level to ensure filtering
    other_level = create(:level, slug: "other-level")
    create(:lesson, level: other_level, slug: "other-lesson", title: "Other Lesson")

    expected_lessons = [
      {
        id: lesson_1.id,
        slug: "lesson-1",
        title: "Lesson 1",
        description: lesson_1.description,
        type: lesson_1.type,
        position: lesson_1.position,
        data: lesson_1.data
      },
      {
        id: lesson_2.id,
        slug: "lesson-2",
        title: "Lesson 2",
        description: lesson_2.description,
        type: lesson_2.type,
        position: lesson_2.position,
        data: lesson_2.data
      }
    ]

    Prosopite.scan
    get v1_admin_level_lessons_path(@level), headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      lessons: expected_lessons
    })
  end

  test "GET index returns empty array when level has no lessons" do
    get v1_admin_level_lessons_path(@level), headers: @headers, as: :json

    assert_response :success
    assert_json_response({ lessons: [] })
  end

  test "GET index returns 404 for non-existent level" do
    get v1_admin_level_lessons_path(level_id: 99_999), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Level not found"
      }
    })
  end

  test "GET index uses SerializeAdminLessons" do
    Prosopite.finish
    lessons = create_list(:lesson, 2, level: @level)
    Prosopite.scan

    SerializeAdminLessons.expects(:call).with do |arg|
      arg.to_a == lessons
    end.returns([])

    get v1_admin_level_lessons_path(@level), headers: @headers, as: :json

    assert_response :success
  end

  test "GET index does not paginate results" do
    Prosopite.finish
    # Create more than default page size to verify no pagination
    26.times { |i| create(:lesson, level: @level, slug: "lesson-#{i}") }
    Prosopite.scan

    get v1_admin_level_lessons_path(@level), headers: @headers, as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 26, json["lessons"].length
    refute json.key?("meta"), "Should not include pagination meta"
  end

  # UPDATE tests

  test "PATCH update calls Lesson::Update command with correct params" do
    lesson = create(:lesson, level: @level, slug: "update-command-test")
    Lesson::Update.expects(:call).with(
      lesson,
      { "title" => "New Title", "description" => "New description" }
    ).returns(lesson)

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: {
        lesson: {
          title: "New Title",
          description: "New description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "PATCH update returns updated lesson" do
    lesson = create(:lesson, level: @level, slug: "update-returns-test", title: "Old Title")

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: {
        lesson: {
          title: "New Title",
          description: "New description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success

    json = response.parsed_body
    assert_equal "New Title", json["lesson"]["title"]
    assert_equal "New description", json["lesson"]["description"]
  end

  test "PATCH update can update type" do
    lesson = create(:lesson, level: @level, slug: "update-type-test", type: "coding")

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { type: "reading" } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal "reading", json["lesson"]["type"]
  end

  test "PATCH update can update position" do
    lesson = create(:lesson, level: @level, slug: "update-position-test", position: 1)

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { position: 5 } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 5, json["lesson"]["position"]
  end

  test "PATCH update can update data" do
    lesson = create(:lesson, level: @level, slug: "update-data-test", data: { key: "old" })

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { data: { key: "new", foo: "bar" } } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal({ "key" => "new", "foo" => "bar" }, json["lesson"]["data"])
  end

  test "PATCH update returns 422 for validation errors" do
    lesson = create(:lesson, level: @level, slug: "update-validation-test")

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: {
        lesson: {
          title: ""
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_match(/Validation failed/, json["error"]["message"])
  end

  test "PATCH update returns 404 for non-existent level" do
    lesson = create(:lesson, level: @level)

    patch v1_admin_level_lesson_path(level_id: 99_999, id: lesson.id),
      params: { lesson: { title: "New" } },
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Level not found"
      }
    })
  end

  test "PATCH update returns 404 for non-existent lesson" do
    patch v1_admin_level_lesson_path(@level, id: 99_999),
      params: { lesson: { title: "New" } },
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

  test "PATCH update returns 404 for lesson in different level" do
    other_level = create(:level, slug: "other-level")
    lesson = create(:lesson, level: other_level)

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { title: "New" } },
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

  test "PATCH update uses SerializeAdminLesson" do
    lesson = create(:lesson, level: @level, slug: "serialize-test")
    Lesson::Update.stubs(:call).returns(lesson)

    SerializeAdminLesson.expects(:call).with(lesson).returns({ id: lesson.id })

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { title: "Updated" } },
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "PATCH update can handle nested JSON data structure" do
    lesson = create(:lesson, level: @level, slug: "nested-data-test", data: { simple: "value" })

    complex_data = {
      nested: {
        deeply: {
          nested: {
            array: [1, 2, { key: "value" }],
            string: "test",
            number: 42,
            boolean: true
          }
        }
      },
      top_level: "value"
    }

    patch v1_admin_level_lesson_path(@level, lesson.id),
      params: { lesson: { data: complex_data } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal complex_data.deep_stringify_keys, json["lesson"]["data"]
  end
end

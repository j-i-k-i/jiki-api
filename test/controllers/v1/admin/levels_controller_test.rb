require "test_helper"

class V1::Admin::LevelsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
  end

  # Authentication and authorization guards
  guard_admin! :v1_admin_levels_path, method: :get
  guard_admin! :v1_admin_levels_path, method: :post
  guard_admin! :v1_admin_level_path, args: [1], method: :patch

  # CREATE tests

  test "POST create calls Level::Create command with correct params" do
    Level::Create.expects(:call).with(
      { "slug" => "ruby-basics", "title" => "Ruby Basics", "description" => "Learn Ruby" }
    ).returns(create(:level))

    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "Ruby Basics",
          description: "Learn Ruby"
        }
      },
      headers: @headers,
      as: :json

    assert_response :created
  end

  test "POST create returns created level" do
    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "Ruby Basics",
          description: "Learn the fundamentals of Ruby"
        }
      },
      headers: @headers,
      as: :json

    assert_response :created

    json = response.parsed_body
    assert_equal "ruby-basics", json["level"]["slug"]
    assert_equal "Ruby Basics", json["level"]["title"]
    assert_equal "Learn the fundamentals of Ruby", json["level"]["description"]
    assert json["level"]["position"].present?
  end

  test "POST create auto-assigns position" do
    create(:level, position: 1)
    create(:level, position: 2)

    post v1_admin_levels_path,
      params: {
        level: {
          slug: "new-level",
          title: "New Level",
          description: "Description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :created
    json = response.parsed_body
    assert_equal 3, json["level"]["position"]
  end

  test "POST create accepts explicit position" do
    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "Ruby Basics",
          description: "Description",
          position: 5
        }
      },
      headers: @headers,
      as: :json

    assert_response :created
    json = response.parsed_body
    assert_equal 5, json["level"]["position"]
  end

  test "POST create returns 422 for missing slug" do
    post v1_admin_levels_path,
      params: {
        level: {
          title: "Ruby Basics",
          description: "Description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_match(/Validation failed/, json["error"]["message"])
  end

  test "POST create returns 422 for missing title" do
    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          description: "Description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
  end

  test "POST create returns 422 for missing description" do
    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "Ruby Basics"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
  end

  test "POST create returns 422 for blank title" do
    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "",
          description: "Description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
  end

  test "POST create returns 422 for duplicate slug" do
    create(:level, slug: "ruby-basics")

    post v1_admin_levels_path,
      params: {
        level: {
          slug: "ruby-basics",
          title: "Another Level",
          description: "Description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
  end

  test "POST create returns 422 for duplicate position" do
    create(:level, position: 1)

    post v1_admin_levels_path,
      params: {
        level: {
          slug: "new-level",
          title: "New Level",
          description: "Description",
          position: 1
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
  end

  test "POST create uses SerializeAdminLevel" do
    level = create(:level)
    Level::Create.stubs(:call).returns(level)

    SerializeAdminLevel.expects(:call).with(level).returns({ id: level.id })

    post v1_admin_levels_path,
      params: {
        level: {
          slug: "test",
          title: "Test",
          description: "Test"
        }
      },
      headers: @headers,
      as: :json

    assert_response :created
  end

  # INDEX tests

  test "GET index returns all levels with pagination meta" do
    Prosopite.finish
    level_1 = create(:level, title: "Level 1", slug: "level-1")
    level_2 = create(:level, title: "Level 2", slug: "level-2")

    expected_levels = [
      { id: level_1.id, slug: "level-1", title: "Level 1", description: level_1.description, position: level_1.position },
      { id: level_2.id, slug: "level-2", title: "Level 2", description: level_2.description, position: level_2.position }
    ]

    Prosopite.scan
    get v1_admin_levels_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      results: expected_levels,
      meta: {
        current_page: 1,
        total_pages: 1,
        total_count: 2
      }
    })
  end

  test "GET index calls Level::Search with correct params" do
    Prosopite.finish
    levels = create_list(:level, 2)
    Prosopite.scan
    paginated_levels = Kaminari.paginate_array(levels, total_count: 2).page(1).per(24)

    Level::Search.expects(:call).with(
      title: "Ruby",
      slug: "basics",
      page: "2",
      per: nil
    ).returns(paginated_levels)

    get v1_admin_levels_path(title: "Ruby", slug: "basics", page: 2),
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "GET index filters by title parameter" do
    create(:level, title: "Ruby Basics")
    advanced = create(:level, title: "Ruby Advanced")

    get v1_admin_levels_path(title: "Advanced"),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["results"].length
    assert_equal advanced.id, json["results"][0]["id"]
  end

  test "GET index filters by slug parameter" do
    create(:level, slug: "ruby-basics")
    advanced = create(:level, slug: "ruby-advanced")

    get v1_admin_levels_path(slug: "advanced"),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["results"].length
    assert_equal advanced.id, json["results"][0]["id"]
  end

  test "GET index paginates results" do
    Prosopite.finish
    3.times { |i| create(:level, slug: "level-#{i}") }

    Prosopite.scan
    get v1_admin_levels_path(page: 1, per: 2),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 2, json["results"].length
    assert_equal 1, json["meta"]["current_page"]
    assert_equal 2, json["meta"]["total_pages"]
    assert_equal 3, json["meta"]["total_count"]
  end

  test "GET index uses SerializePaginatedCollection with SerializeAdminLevels" do
    Prosopite.finish
    levels = create_list(:level, 2)
    paginated_levels = Kaminari.paginate_array(levels, total_count: 2).page(1).per(24)

    Level::Search.expects(:call).returns(paginated_levels)
    SerializePaginatedCollection.expects(:call).with(
      paginated_levels,
      serializer: SerializeAdminLevels
    ).returns({ results: [], meta: {} })

    Prosopite.scan
    get v1_admin_levels_path, headers: @headers, as: :json

    assert_response :success
  end

  # UPDATE tests

  test "PATCH update calls Level::Update command with correct params" do
    level = create(:level)
    Level::Update.expects(:call).with(
      level,
      { "title" => "New Title", "description" => "New description" }
    ).returns(level)

    patch v1_admin_level_path(level),
      params: {
        level: {
          title: "New Title",
          description: "New description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "PATCH update returns updated level" do
    level = create(:level, title: "Old Title")

    patch v1_admin_level_path(level),
      params: {
        level: {
          title: "New Title",
          description: "New description"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success

    json = response.parsed_body
    assert_equal "New Title", json["level"]["title"]
    assert_equal "New description", json["level"]["description"]
  end

  test "PATCH update can update position" do
    level = create(:level, position: 1)

    patch v1_admin_level_path(level),
      params: { level: { position: 5 } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 5, json["level"]["position"]
  end

  test "PATCH update can update slug" do
    level = create(:level, slug: "old-slug")

    patch v1_admin_level_path(level),
      params: { level: { slug: "new-slug" } },
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal "new-slug", json["level"]["slug"]
  end

  test "PATCH update returns 422 for validation errors" do
    level = create(:level)

    patch v1_admin_level_path(level),
      params: {
        level: {
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
    patch v1_admin_level_path(id: 99_999),
      params: { level: { title: "New" } },
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

  test "PATCH update uses SerializeAdminLevel" do
    level = create(:level)
    Level::Update.stubs(:call).returns(level)

    SerializeAdminLevel.expects(:call).with(level).returns({ id: level.id })

    patch v1_admin_level_path(level),
      params: { level: { title: "Updated" } },
      headers: @headers,
      as: :json

    assert_response :success
  end
end

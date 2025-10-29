require "test_helper"

class V1::Admin::UsersControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
  end

  # Authentication and authorization guards
  guard_admin! :v1_admin_users_path, method: :get
  guard_admin! :v1_admin_user_path, args: [1], method: :get
  guard_admin! :v1_admin_user_path, args: [1], method: :patch
  guard_admin! :v1_admin_user_path, args: [1], method: :delete

  # INDEX tests

  test "GET index returns all users with pagination meta" do
    Prosopite.finish # Stop scan before creating test data
    user_1 = create(:user, name: "User 1", email: "user1@example.com", admin: false)
    user_2 = create(:user, name: "User 2", email: "user2@example.com", admin: false)

    expected_users = [
      { id: @admin.id, name: @admin.name, email: @admin.email, locale: @admin.locale, admin: true },
      { id: user_1.id, name: "User 1", email: "user1@example.com", locale: user_1.locale, admin: false },
      { id: user_2.id, name: "User 2", email: "user2@example.com", locale: user_2.locale, admin: false }
    ]

    Prosopite.scan # Resume scan for the actual request
    get v1_admin_users_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      results: expected_users,
      meta: {
        current_page: 1,
        total_pages: 1,
        total_count: 3
      }
    })
  end

  test "GET index returns empty results when only admin exists" do
    # Only admin exists (created in setup), no other users
    get v1_admin_users_path, headers: @headers, as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["results"].length # Just the admin
    assert_equal @admin.id, json["results"][0]["id"]
  end

  test "GET index calls User::Search with correct params" do
    users = create_list(:user, 2)
    paginated_users = Kaminari.paginate_array(users, total_count: 2).page(1).per(24)

    User::Search.expects(:call).with(
      name: "Test",
      email: "test@example.com",
      page: "2",
      per: nil
    ).returns(paginated_users)

    get v1_admin_users_path(name: "Test", email: "test@example.com", page: 2),
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "GET index filters by name parameter" do
    create(:user, name: "Alice Smith")
    bob = create(:user, name: "Bob Jones")

    get v1_admin_users_path(name: "Bob"),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["results"].length
    assert_equal bob.id, json["results"][0]["id"]
  end

  test "GET index filters by email parameter" do
    create(:user, email: "alice@example.com")
    bob = create(:user, email: "bob@test.org")

    get v1_admin_users_path(email: "test.org"),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["results"].length
    assert_equal bob.id, json["results"][0]["id"]
  end

  test "GET index paginates results" do
    Prosopite.finish
    3.times { create(:user) }

    Prosopite.scan
    get v1_admin_users_path(page: 1, per: 2),
      headers: @headers,
      as: :json

    assert_response :success
    json = response.parsed_body
    assert_equal 2, json["results"].length
    assert_equal 1, json["meta"]["current_page"]
    assert_equal 2, json["meta"]["total_pages"]
    assert_equal 4, json["meta"]["total_count"] # 3 users + admin
  end

  test "GET index uses SerializePaginatedCollection with SerializeAdminUsers" do
    Prosopite.finish
    users = create_list(:user, 2)
    paginated_users = Kaminari.paginate_array(users, total_count: 2).page(1).per(24)

    User::Search.expects(:call).returns(paginated_users)
    SerializePaginatedCollection.expects(:call).with(
      paginated_users,
      serializer: SerializeAdminUsers
    ).returns({ results: [], meta: {} })

    Prosopite.scan
    get v1_admin_users_path, headers: @headers, as: :json

    assert_response :success
  end

  # SHOW tests

  test "GET show returns single user with full data using SerializeAdminUser" do
    user = create(:user, name: "Test User", email: "test@example.com")

    get v1_admin_user_path(user), headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      user: {
        id: user.id,
        name: "Test User",
        email: "test@example.com",
        locale: user.locale,
        admin: false
      }
    })
  end

  test "GET show returns 404 for non-existent user" do
    get v1_admin_user_path(99_999), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "User not found"
      }
    })
  end

  # UPDATE tests

  test "PATCH update calls User::Update command with correct params" do
    user = create(:user)
    User::Update.expects(:call).with(
      user,
      { "email" => "newemail@example.com" }
    ).returns(user)

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "newemail@example.com"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success
  end

  test "PATCH update successfully updates email" do
    user = create(:user, email: "old@example.com")

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "new@example.com"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success

    json = response.parsed_body
    assert_equal "new@example.com", json["user"]["email"]
    assert_equal "new@example.com", user.reload.email
  end

  test "PATCH update returns updated user with SerializeAdminUser" do
    user = create(:user, email: "old@example.com", name: "Original Name")

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "updated@example.com"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success
    assert_json_response({
      user: {
        id: user.id,
        name: "Original Name",
        email: "updated@example.com",
        locale: user.locale,
        admin: false
      }
    })
  end

  test "PATCH update returns 404 for non-existent user" do
    patch v1_admin_user_path(99_999),
      params: { user: { email: "new@example.com" } },
      headers: @headers,
      as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "User not found"
      }
    })
  end

  test "PATCH update returns 422 for blank email" do
    user = create(:user)

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: ""
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_match(/Validation failed/, json["error"]["message"])
  end

  test "PATCH update returns 422 for invalid email format" do
    user = create(:user)

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "not-an-email"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_match(/Validation failed/, json["error"]["message"])
  end

  test "PATCH update returns 422 for duplicate email" do
    create(:user, email: "existing@example.com")
    user = create(:user, email: "unique@example.com")

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "existing@example.com"
        }
      },
      headers: @headers,
      as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_match(/has already been taken/, json["error"]["message"])
  end

  test "PATCH update ignores non-email fields" do
    user = create(:user, name: "Original Name", email: "original@example.com", admin: false)

    patch v1_admin_user_path(user),
      params: {
        user: {
          email: "new@example.com",
          name: "Hacker Name",
          admin: true,
          locale: "fr"
        }
      },
      headers: @headers,
      as: :json

    assert_response :success

    user.reload
    assert_equal "new@example.com", user.email
    assert_equal "Original Name", user.name
    refute user.admin
    refute_equal "fr", user.locale
  end

  # DELETE tests

  test "DELETE destroy calls User::Destroy command" do
    user = create(:user)
    User::Destroy.expects(:call).with(user)

    delete v1_admin_user_path(user), headers: @headers, as: :json

    assert_response :no_content
  end

  test "DELETE destroy deletes user successfully" do
    user = create(:user)
    user_id = user.id

    assert_difference -> { User.count }, -1 do
      delete v1_admin_user_path(user), headers: @headers, as: :json
    end

    assert_response :no_content
    assert_nil User.find_by(id: user_id)
  end

  test "DELETE destroy returns 404 for non-existent user" do
    delete v1_admin_user_path(99_999), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "User not found"
      }
    })
  end
end

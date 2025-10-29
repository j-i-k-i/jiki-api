require "test_helper"

class V1::Admin::ProjectsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
  end

  # Authentication and authorization guards
  guard_admin! :v1_admin_projects_path, method: :get
  guard_admin! :v1_admin_projects_path, method: :post
  guard_admin! :v1_admin_project_path, args: [1], method: :get
  guard_admin! :v1_admin_project_path, args: [1], method: :patch
  guard_admin! :v1_admin_project_path, args: [1], method: :delete

  # INDEX tests

  test "GET index returns all projects with pagination" do
    Prosopite.finish # Stop scan before creating test data
    project1 = create(:project, title: "Calculator", slug: "calculator")
    project2 = create(:project, title: "Todo App", slug: "todo-app")

    expected_projects = [
      {
        id: project1.id,
        title: "Calculator",
        slug: "calculator",
        description: project1.description,
        exercise_slug: project1.exercise_slug
      },
      {
        id: project2.id,
        title: "Todo App",
        slug: "todo-app",
        description: project2.description,
        exercise_slug: project2.exercise_slug
      }
    ]

    Prosopite.scan # Resume scan for the actual request
    get v1_admin_projects_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      results: expected_projects,
      meta: {
        current_page: 1,
        total_pages: 1,
        total_count: 2
      }
    })
  end

  test "GET index filters by title" do
    Prosopite.finish
    project1 = create(:project)
    project1.update!(title: "Calculator App")
    project2 = create(:project)
    project2.update!(title: "Todo List")

    Prosopite.scan
    get v1_admin_projects_path(title: "Calculator"), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 1, json[:results].length
    assert_equal project1.id, json[:results][0][:id]
  end

  test "GET index supports pagination" do
    Prosopite.finish
    3.times { create(:project) }

    Prosopite.scan
    get v1_admin_projects_path(page: 1, per: 2), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 2, json[:results].length
    assert_equal 2, json[:meta][:total_pages]
    assert_equal 3, json[:meta][:total_count]
  end

  test "GET index returns empty results when no projects exist" do
    get v1_admin_projects_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      results: [],
      meta: {
        current_page: 1,
        total_pages: 0,
        total_count: 0
      }
    })
  end

  # CREATE tests

  test "POST create creates project with valid attributes" do
    project_params = {
      project: {
        title: "Calculator",
        slug: "calculator",
        description: "Build a calculator application",
        exercise_slug: "calculator-project"
      }
    }

    assert_difference "Project.count", 1 do
      post v1_admin_projects_path, params: project_params, headers: @headers, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Calculator", json[:project][:title]
    assert_equal "calculator", json[:project][:slug]
    assert_equal "Build a calculator application", json[:project][:description]
    assert_equal "calculator-project", json[:project][:exercise_slug]
  end

  test "POST create returns validation error for invalid attributes" do
    project_params = {
      project: {
        title: ""
      }
    }

    assert_no_difference "Project.count" do
      post v1_admin_projects_path, params: project_params, headers: @headers, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", json[:error][:type]
  end

  # SHOW tests

  test "GET show returns project" do
    project = create(:project, title: "Calculator", exercise_slug: "calculator-project")

    get v1_admin_project_path(project.id), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Calculator", json[:project][:title]
    assert_equal "calculator-project", json[:project][:exercise_slug]
  end

  test "GET show returns 404 for non-existent project" do
    get v1_admin_project_path(999_999), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Project not found"
      }
    })
  end

  # UPDATE tests

  test "PATCH update updates project with valid attributes" do
    project = create(:project, title: "Original")
    update_params = {
      project: {
        title: "Updated"
      }
    }

    patch v1_admin_project_path(project.id), params: update_params, headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Updated", json[:project][:title]
    assert_equal "Updated", project.reload.title
  end

  test "PATCH update returns validation error for invalid attributes" do
    project = create(:project)
    update_params = {
      project: {
        title: ""
      }
    }

    patch v1_admin_project_path(project.id), params: update_params, headers: @headers, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", json[:error][:type]
  end

  test "PATCH update returns 404 for non-existent project" do
    update_params = {
      project: {
        title: "Updated"
      }
    }

    patch v1_admin_project_path(999_999), params: update_params, headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Project not found"
      }
    })
  end

  # DESTROY tests

  test "DELETE destroy deletes project" do
    project = create(:project)

    assert_difference "Project.count", -1 do
      delete v1_admin_project_path(project.id), headers: @headers, as: :json
    end

    assert_response :no_content
  end

  test "DELETE destroy returns 404 for non-existent project" do
    delete v1_admin_project_path(999_999), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Project not found"
      }
    })
  end
end

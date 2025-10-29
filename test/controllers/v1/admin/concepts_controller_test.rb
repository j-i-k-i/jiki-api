require "test_helper"

class V1::Admin::ConceptsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
  end

  # Authentication and authorization guards
  guard_admin! :v1_admin_concepts_path, method: :get
  guard_admin! :v1_admin_concepts_path, method: :post
  guard_admin! :v1_admin_concept_path, args: [1], method: :get
  guard_admin! :v1_admin_concept_path, args: [1], method: :patch
  guard_admin! :v1_admin_concept_path, args: [1], method: :delete

  # INDEX tests

  test "GET index returns all concepts with pagination" do
    Prosopite.finish # Stop scan before creating test data
    concept1 = create(:concept, title: "Strings", slug: "strings")
    concept2 = create(:concept, title: "Arrays", slug: "arrays")

    expected_concepts = [
      {
        id: concept1.id,
        title: "Strings",
        slug: "strings",
        description: concept1.description,
        standard_video_provider: nil,
        standard_video_id: nil,
        premium_video_provider: nil,
        premium_video_id: nil
      },
      {
        id: concept2.id,
        title: "Arrays",
        slug: "arrays",
        description: concept2.description,
        standard_video_provider: nil,
        standard_video_id: nil,
        premium_video_provider: nil,
        premium_video_id: nil
      }
    ]

    Prosopite.scan # Resume scan for the actual request
    get v1_admin_concepts_path, headers: @headers, as: :json

    assert_response :success
    assert_json_response({
      results: expected_concepts,
      meta: {
        current_page: 1,
        total_pages: 1,
        total_count: 2
      }
    })
  end

  test "GET index filters by title" do
    Prosopite.finish
    concept1 = create(:concept)
    concept1.update!(title: "Strings and Text")
    concept2 = create(:concept)
    concept2.update!(title: "Arrays")

    Prosopite.scan
    get v1_admin_concepts_path(title: "String"), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 1, json[:results].length
    assert_equal concept1.id, json[:results][0][:id]
  end

  test "GET index supports pagination" do
    Prosopite.finish
    3.times { create(:concept) }

    Prosopite.scan
    get v1_admin_concepts_path(page: 1, per: 2), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal 2, json[:results].length
    assert_equal 2, json[:meta][:total_pages]
    assert_equal 3, json[:meta][:total_count]
  end

  test "GET index returns empty results when no concepts exist" do
    get v1_admin_concepts_path, headers: @headers, as: :json

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

  test "POST create creates concept with valid attributes" do
    concept_params = {
      concept: {
        title: "Strings",
        slug: "strings",
        description: "Learn about strings",
        content_markdown: "# Strings\n\nText content"
      }
    }

    assert_difference "Concept.count", 1 do
      post v1_admin_concepts_path, params: concept_params, headers: @headers, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Strings", json[:concept][:title]
    assert_equal "strings", json[:concept][:slug]
    assert_equal "Learn about strings", json[:concept][:description]
    assert_equal "# Strings\n\nText content", json[:concept][:content_markdown]
  end

  test "POST create with video providers" do
    concept_params = {
      concept: {
        title: "Strings",
        description: "Learn about strings",
        content_markdown: "# Strings",
        standard_video_provider: "youtube",
        standard_video_id: "abc123",
        premium_video_provider: "mux",
        premium_video_id: "def456"
      }
    }

    post v1_admin_concepts_path, params: concept_params, headers: @headers, as: :json

    assert_response :created
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "youtube", json[:concept][:standard_video_provider]
    assert_equal "abc123", json[:concept][:standard_video_id]
    assert_equal "mux", json[:concept][:premium_video_provider]
    assert_equal "def456", json[:concept][:premium_video_id]
  end

  test "POST create returns validation error for invalid attributes" do
    concept_params = {
      concept: {
        title: ""
      }
    }

    assert_no_difference "Concept.count" do
      post v1_admin_concepts_path, params: concept_params, headers: @headers, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", json[:error][:type]
  end

  # SHOW tests

  test "GET show returns concept with markdown" do
    concept = create(:concept, title: "Strings", content_markdown: "# Strings\n\nContent")

    get v1_admin_concept_path(concept), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Strings", json[:concept][:title]
    assert_equal "# Strings\n\nContent", json[:concept][:content_markdown]
  end

  test "GET show returns 404 for non-existent concept" do
    get v1_admin_concept_path(id: "non-existent"), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Concept not found"
      }
    })
  end

  # UPDATE tests

  test "PATCH update updates concept with valid attributes" do
    concept = create(:concept, title: "Original")
    update_params = {
      concept: {
        title: "Updated"
      }
    }

    patch v1_admin_concept_path(concept), params: update_params, headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Updated", json[:concept][:title]
    assert_equal "Updated", concept.reload.title
  end

  test "PATCH update updates markdown and regenerates HTML" do
    concept = create(:concept, content_markdown: "# Original")
    update_params = {
      concept: {
        content_markdown: "# Updated"
      }
    }

    patch v1_admin_concept_path(concept), params: update_params, headers: @headers, as: :json

    assert_response :success
    assert_equal "# Updated", concept.reload.content_markdown
    assert_includes concept.content_html, "Updated"
  end

  test "PATCH update returns validation error for invalid attributes" do
    concept = create(:concept)
    update_params = {
      concept: {
        title: ""
      }
    }

    patch v1_admin_concept_path(concept), params: update_params, headers: @headers, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "validation_error", json[:error][:type]
  end

  test "PATCH update returns 404 for non-existent concept" do
    update_params = {
      concept: {
        title: "Updated"
      }
    }

    patch v1_admin_concept_path(id: "non-existent"), params: update_params, headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Concept not found"
      }
    })
  end

  # DESTROY tests

  test "DELETE destroy deletes concept" do
    concept = create(:concept)

    assert_difference "Concept.count", -1 do
      delete v1_admin_concept_path(concept), headers: @headers, as: :json
    end

    assert_response :no_content
  end

  test "DELETE destroy returns 404 for non-existent concept" do
    delete v1_admin_concept_path(id: "non-existent"), headers: @headers, as: :json

    assert_response :not_found
    assert_json_response({
      error: {
        type: "not_found",
        message: "Concept not found"
      }
    })
  end

  # SLUG HISTORY tests

  test "GET show finds concept by old slug after slug change" do
    concept = create(:concept, slug: "old-slug", title: "Original Title")
    original_id = concept.id

    # Update the slug
    concept.update!(slug: "new-slug")

    # Should find by old slug
    get v1_admin_concept_path(id: "old-slug"), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal original_id, json[:concept][:id]
    assert_equal "new-slug", json[:concept][:slug]
  end

  test "GET show finds concept by current slug after slug change" do
    concept = create(:concept, slug: "old-slug")
    concept.update!(slug: "new-slug")

    # Should still find by new slug
    get v1_admin_concept_path(id: "new-slug"), headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal concept.id, json[:concept][:id]
    assert_equal "new-slug", json[:concept][:slug]
  end

  test "PATCH update works with old slug" do
    concept = create(:concept, slug: "old-slug", title: "Original")
    concept.update!(slug: "new-slug")

    update_params = {
      concept: {
        title: "Updated via old slug"
      }
    }

    # Update using old slug
    patch v1_admin_concept_path(id: "old-slug"), params: update_params, headers: @headers, as: :json

    assert_response :success
    json = JSON.parse(response.body, symbolize_names: true)
    assert_equal "Updated via old slug", json[:concept][:title]
    assert_equal "Updated via old slug", concept.reload.title
  end

  test "DELETE destroy works with old slug" do
    concept = create(:concept, slug: "old-slug")
    concept.update!(slug: "new-slug")

    assert_difference "Concept.count", -1 do
      delete v1_admin_concept_path(id: "old-slug"), headers: @headers, as: :json
    end

    assert_response :no_content
  end

  test "slug history persists through multiple slug changes" do
    Prosopite.finish # Disable N+1 detection - intentionally querying multiple times in a loop
    concept = create(:concept, slug: "slug-v1")
    original_id = concept.id

    # Change slug twice
    concept.update!(slug: "slug-v2")
    concept.update!(slug: "slug-v3")

    # All three slugs should work
    %w[slug-v1 slug-v2 slug-v3].each do |slug|
      get v1_admin_concept_path(id: slug), headers: @headers, as: :json

      assert_response :success, "Failed to find concept by slug: #{slug}"
      json = JSON.parse(response.body, symbolize_names: true)
      assert_equal original_id, json[:concept][:id]
      assert_equal "slug-v3", json[:concept][:slug], "Should return current slug"
    end
  end
end

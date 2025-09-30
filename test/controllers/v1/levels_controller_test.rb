require "test_helper"

module V1
  class LevelsControllerTest < ApplicationControllerTest
    setup do
      setup_user
    end

    # Authentication guards
    guard_incorrect_token! :v1_levels_path, method: :get

    test "GET index returns all levels with nested lessons" do
      level1 = create(:level, slug: "level-1")
      level2 = create(:level, slug: "level-2")
      create(:lesson, level: level1, slug: "lesson-1", type: "exercise", data: { slug: :ex1 })
      create(:lesson, level: level1, slug: "lesson-2", type: "tutorial", data: { slug: :ex2 })
      create(:lesson, level: level2, slug: "lesson-3", type: "exercise", data: { slug: :ex3 })

      get v1_levels_path, headers: @headers, as: :json

      assert_response :success

      json = response.parsed_body
      assert json["levels"].present?
      assert_equal 2, json["levels"].length

      # Check first level
      assert_equal "level-1", json["levels"][0]["slug"]
      assert_equal 2, json["levels"][0]["lessons"].length
      assert_equal "lesson-1", json["levels"][0]["lessons"][0]["slug"]
      assert_equal "exercise", json["levels"][0]["lessons"][0]["type"]
      assert_equal({ "slug" => "ex1" }, json["levels"][0]["lessons"][0]["data"])

      # Check second level
      assert_equal "level-2", json["levels"][1]["slug"]
      assert_equal 1, json["levels"][1]["lessons"].length
      assert_equal "lesson-3", json["levels"][1]["lessons"][0]["slug"]
    end

    test "GET index returns empty array when no levels exist" do
      get v1_levels_path, headers: @headers, as: :json

      assert_response :success

      json = response.parsed_body
      assert_empty json["levels"]
    end

    test "GET index returns correct JSON structure" do
      level = create(:level)
      create(:lesson, level: level)

      get v1_levels_path, headers: @headers, as: :json

      assert_response :success

      assert_json_structure({
        levels: [
          {
            slug: String,
            lessons: [
              {
                slug: String,
                type: String,
                data: Hash
              }
            ]
          }
        ]
      })
    end

    test "GET index uses SerializeLevels" do
      level = create(:level)
      create(:lesson, level: level)

      get v1_levels_path, headers: @headers, as: :json

      assert_response :success
      json = response.parsed_body

      # Verify the serializer was used by checking the structure
      assert json["levels"][0].key?("slug")
      assert json["levels"][0].key?("lessons")
      refute json["levels"][0].key?("title") # Title should not be included
      refute json["levels"][0].key?("description") # Description should not be included
    end
  end
end

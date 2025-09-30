require "test_helper"

class Level::CreateAllFromJsonTest < ActiveSupport::TestCase
  test "imports levels and lessons from valid JSON" do
    file_path = Rails.root.join("curriculum.json")

    result = Level::CreateAllFromJson.(file_path.to_s)

    assert result

    # Verify levels were created
    fundamentals = Level.find_by(slug: "fundamentals")
    assert fundamentals
    assert_equal "Programming Fundamentals", fundamentals.title
    assert_equal 1, fundamentals.position

    variables = Level.find_by(slug: "variables")
    assert variables
    assert_equal "Variables and Assignment", variables.title
    assert_equal 2, variables.position

    # Verify lessons were created
    assert_equal 2, fundamentals.lessons.count
    first_lesson = fundamentals.lessons.find_by(slug: "first-function-call")
    assert first_lesson
    assert_equal "Your First Function Call", first_lesson.title
    assert_equal "exercise", first_lesson.type
    assert_equal({ "slug" => "basic-movement" }, first_lesson.data)
    assert_equal 1, first_lesson.position
  end

  test "is idempotent - running twice updates existing records" do
    file_path = Rails.root.join("curriculum.json")

    # First run
    Level::CreateAllFromJson.(file_path.to_s)

    # Second run
    Level::CreateAllFromJson.(file_path.to_s)

    # Verify counts haven't changed
    assert_equal 2, Level.count
    assert_equal 4, Lesson.count
  end

  test "raises error for non-existent file" do
    error = assert_raises Level::CreateAllFromJson::InvalidJsonError do
      Level::CreateAllFromJson.("nonexistent.json")
    end

    assert_match(/File not found/, error.message)
  end

  test "raises error for invalid JSON" do
    file = Tempfile.new(['invalid', '.json'])
    file.write("{ invalid json")
    file.close

    error = assert_raises Level::CreateAllFromJson::InvalidJsonError do
      Level::CreateAllFromJson.(file.path)
    end

    assert_match(/Invalid JSON/, error.message)
  ensure
    file.unlink
  end

  test "raises error for JSON missing levels array" do
    file = Tempfile.new(['missing', '.json'])
    file.write('{ "something": "else" }')
    file.close

    error = assert_raises Level::CreateAllFromJson::InvalidJsonError do
      Level::CreateAllFromJson.(file.path)
    end

    assert_match(/missing 'levels' array/, error.message)
  ensure
    file.unlink
  end

  test "raises error for level missing required fields" do
    file = Tempfile.new(['missing_fields', '.json'])
    file.write('{ "levels": [{ "slug": "test" }] }')
    file.close

    error = assert_raises Level::CreateAllFromJson::InvalidJsonError do
      Level::CreateAllFromJson.(file.path)
    end

    assert_match(/missing required 'title' field/, error.message)
  ensure
    file.unlink
  end

  test "wraps everything in transaction - rolls back on error" do
    file = Tempfile.new(['partial', '.json'])
    file.write('{
      "levels": [
        {
          "slug": "valid-level",
          "title": "Valid Level",
          "description": "This is valid",
          "lessons": []
        },
        {
          "slug": "invalid-level"
        }
      ]
    }')
    file.close

    assert_raises Level::CreateAllFromJson::InvalidJsonError do
      Level::CreateAllFromJson.(file.path)
    end

    # Nothing should be created due to transaction rollback
    assert_equal 0, Level.where(slug: "valid-level").count
  ensure
    file.unlink
  end

  test "updates title and description on existing records" do
    # Create initial level
    level = create(:level, slug: "fundamentals", title: "Old Title", description: "Old description")

    file = Tempfile.new(['update', '.json'])
    file.write('{
      "levels": [{
        "slug": "fundamentals",
        "title": "New Title",
        "description": "New description",
        "lessons": []
      }]
    }')
    file.close

    Level::CreateAllFromJson.(file.path)

    level.reload
    assert_equal "New Title", level.title
    assert_equal "New description", level.description
  ensure
    file.unlink
  end
end

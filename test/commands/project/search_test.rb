require "test_helper"

class Project::SearchTest < ActiveSupport::TestCase
  test "no options returns all projects paginated" do
    project_1 = create :project
    project_2 = create :project

    result = Project::Search.()

    assert_equal [project_1, project_2], result.to_a
  end

  test "title: search for partial title match" do
    project_1 = create :project, title: "Calculator App"
    project_2 = create :project, title: "Todo List"
    project_3 = create :project, title: "Scientific Calculator"

    assert_equal [project_1, project_2, project_3], Project::Search.(title: "").to_a
    assert_equal [project_1, project_3], Project::Search.(title: "Calculator").to_a
    assert_equal [project_2], Project::Search.(title: "Todo").to_a
    assert_empty Project::Search.(title: "xyz").to_a
  end

  test "title search is case insensitive" do
    project = create :project, title: "Calculator App"

    assert_equal [project], Project::Search.(title: "calculator").to_a
    assert_equal [project], Project::Search.(title: "CALCULATOR").to_a
    assert_equal [project], Project::Search.(title: "CaLcUlAtOr").to_a
  end

  test "pagination" do
    project_1 = create :project
    project_2 = create :project

    assert_equal [project_1], Project::Search.(page: 1, per: 1).to_a
    assert_equal [project_2], Project::Search.(page: 2, per: 1).to_a
  end

  test "returns paginated collection with correct metadata" do
    5.times { create :project }

    result = Project::Search.(page: 2, per: 2)

    assert_equal 2, result.current_page
    assert_equal 5, result.total_count
    assert_equal 3, result.total_pages
    assert_equal 2, result.size
  end

  test "sanitizes SQL wildcards in title search" do
    project1 = create :project, title: "100% Complete"
    create :project, title: "Todo List"
    project3 = create :project, title: "String_Parser"

    # Search for "%" should match literal "%" not act as wildcard
    result = Project::Search.(title: "%").to_a
    assert_equal [project1], result

    # Search for "_" should match literal "_" not act as single-character wildcard
    result = Project::Search.(title: "_").to_a
    assert_equal [project3], result

    # Wildcards should not match everything
    result = Project::Search.(title: "%%").to_a
    assert_empty result
  end
end

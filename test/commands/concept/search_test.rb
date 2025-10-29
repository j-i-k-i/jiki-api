require "test_helper"

class Concept::SearchTest < ActiveSupport::TestCase
  test "no options returns all concepts paginated" do
    concept_1 = create :concept
    concept_2 = create :concept

    result = Concept::Search.()

    assert_equal [concept_1, concept_2], result.to_a
  end

  test "title: search for partial title match" do
    concept_1 = create :concept, title: "Strings and Text"
    concept_2 = create :concept, title: "Arrays"
    concept_3 = create :concept, title: "String Manipulation"

    assert_equal [concept_1, concept_2, concept_3], Concept::Search.(title: "").to_a
    assert_equal [concept_1, concept_3], Concept::Search.(title: "String").to_a
    assert_equal [concept_2], Concept::Search.(title: "Arrays").to_a
    assert_empty Concept::Search.(title: "xyz").to_a
  end

  test "title search is case insensitive" do
    concept = create :concept, title: "Strings and Text"

    assert_equal [concept], Concept::Search.(title: "strings").to_a
    assert_equal [concept], Concept::Search.(title: "STRINGS").to_a
    assert_equal [concept], Concept::Search.(title: "StRiNgS").to_a
  end

  test "pagination" do
    concept_1 = create :concept
    concept_2 = create :concept

    assert_equal [concept_1], Concept::Search.(page: 1, per: 1).to_a
    assert_equal [concept_2], Concept::Search.(page: 2, per: 1).to_a
  end

  test "returns paginated collection with correct metadata" do
    Prosopite.finish # Disable N+1 detection for this test due to FriendlyId slug checks
    5.times { create :concept }

    result = Concept::Search.(page: 2, per: 2)

    assert_equal 2, result.current_page
    assert_equal 5, result.total_count
    assert_equal 3, result.total_pages
    assert_equal 2, result.size
  end

  test "sanitizes SQL wildcards in title search" do
    concept1 = create :concept, title: "100% Complete"
    create :concept, title: "Arrays"
    concept3 = create :concept, title: "String_Manipulation"

    # Search for "%" should match literal "%" not act as wildcard
    result = Concept::Search.(title: "%").to_a
    assert_equal [concept1], result

    # Search for "_" should match literal "_" not act as single-character wildcard
    result = Concept::Search.(title: "_").to_a
    assert_equal [concept3], result

    # Wildcards should not match everything
    result = Concept::Search.(title: "%%").to_a
    assert_empty result
  end
end

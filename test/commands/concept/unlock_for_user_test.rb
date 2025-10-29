require 'test_helper'

class Concept::UnlockForUserTest < ActiveSupport::TestCase
  test "adds concept ID to user data unlocked_concept_ids" do
    user = create :user
    concept = create :concept

    assert_difference -> { user.data.reload.unlocked_concept_ids.length }, 1 do
      Concept::UnlockForUser.(concept, user)
    end

    assert_includes user.data.unlocked_concept_ids, concept.id
  end

  test "is idempotent - calling twice doesn't add duplicate" do
    user = create :user
    concept = create :concept

    Concept::UnlockForUser.(concept, user)
    initial_count = user.data.unlocked_concept_ids.length

    assert_no_difference -> { user.data.reload.unlocked_concept_ids.length } do
      Concept::UnlockForUser.(concept, user)
    end

    assert_equal initial_count, user.data.unlocked_concept_ids.length
  end

  test "multiple users can unlock same concept" do
    user1 = create :user
    user2 = create :user
    concept = create :concept

    Concept::UnlockForUser.(concept, user1)
    Concept::UnlockForUser.(concept, user2)

    assert_includes user1.data.unlocked_concept_ids, concept.id
    assert_includes user2.data.unlocked_concept_ids, concept.id
  end

  test "user can unlock multiple concepts" do
    user = create :user
    concept1 = create :concept
    concept2 = create :concept

    Concept::UnlockForUser.(concept1, user)
    Concept::UnlockForUser.(concept2, user)

    assert_includes user.data.unlocked_concept_ids, concept1.id
    assert_includes user.data.unlocked_concept_ids, concept2.id
    assert_equal 2, user.data.unlocked_concept_ids.length
  end
end

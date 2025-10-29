require 'test_helper'

class UserConcept::CreateTest < ActiveSupport::TestCase
  test "creates a user_concept record" do
    user = create :user
    concept = create :concept

    assert_difference 'UserConcept.count', 1 do
      UserConcept::Create.(user, concept)
    end

    user_concept = UserConcept.last
    assert_equal user, user_concept.user
    assert_equal concept, user_concept.concept
  end

  test "is idempotent - calling twice doesn't create duplicate" do
    user = create :user
    concept = create :concept

    UserConcept::Create.(user, concept)

    assert_no_difference 'UserConcept.count' do
      UserConcept::Create.(user, concept)
    end
  end

  test "returns the user_concept record" do
    user = create :user
    concept = create :concept

    user_concept = UserConcept::Create.(user, concept)

    assert_instance_of UserConcept, user_concept
    assert_equal user, user_concept.user
    assert_equal concept, user_concept.concept
  end

  test "multiple users can unlock same concept" do
    user1 = create :user
    user2 = create :user
    concept = create :concept

    assert_difference 'UserConcept.count', 2 do
      UserConcept::Create.(user1, concept)
      UserConcept::Create.(user2, concept)
    end

    assert UserConcept.exists?(user: user1, concept: concept)
    assert UserConcept.exists?(user: user2, concept: concept)
  end

  test "user can unlock multiple concepts" do
    user = create :user
    concept1 = create :concept
    concept2 = create :concept

    assert_difference 'UserConcept.count', 2 do
      UserConcept::Create.(user, concept1)
      UserConcept::Create.(user, concept2)
    end

    assert UserConcept.exists?(user: user, concept: concept1)
    assert UserConcept.exists?(user: user, concept: concept2)
  end
end

class UserConcept::Create
  include Mandate

  initialize_with :user, :concept

  def call
    UserConcept.find_create_or_find_by!(user: user, concept: concept)
  end
end

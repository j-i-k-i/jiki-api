class Concept::UnlockForUser
  include Mandate

  initialize_with :concept, :user

  def call
    # Use atomic array append to avoid race conditions
    # The WHERE clause prevents duplicates
    updated = User::Data.where(id: user.data.id).
      where.not('? = ANY(unlocked_concept_ids)', concept.id).
      update_all(["unlocked_concept_ids = array_append(unlocked_concept_ids, ?)", concept.id])

    # Reload only if a row was actually updated
    user.data.reload if updated.positive?
  end
end

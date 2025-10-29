class Concept::UnlockForUser
  include Mandate

  initialize_with :concept, :user

  def call
    return if user.data.unlocked_concept_ids.include?(concept.id)

    user.data.unlocked_concept_ids << concept.id
    user.data.save!
  end
end

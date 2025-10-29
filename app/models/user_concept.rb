class UserConcept < ApplicationRecord
  belongs_to :user
  belongs_to :concept

  validates :concept_id, uniqueness: { scope: :user_id }
end

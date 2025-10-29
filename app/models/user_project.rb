class UserProject < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project

  # Validations
  validates :project_id, uniqueness: { scope: :user_id }

  # State helper methods
  def started? = started_at.present?
  def completed? = completed_at.present?
end

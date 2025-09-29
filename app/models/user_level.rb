class UserLevel < ApplicationRecord
  belongs_to :user
  belongs_to :level

  validates :user_id, uniqueness: { scope: :level_id }
end

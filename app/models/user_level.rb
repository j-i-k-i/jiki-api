class UserLevel < ApplicationRecord
  belongs_to :user
  belongs_to :level
  belongs_to :current_user_lesson, class_name: "UserLesson", optional: true

  validates :user_id, uniqueness: { scope: :level_id }
  validates :started_at, presence: true
end

class UserLesson < ApplicationRecord
  belongs_to :user
  belongs_to :lesson
  has_many :exercise_submissions, dependent: :destroy

  validates :user_id, uniqueness: { scope: :lesson_id }
  validates :started_at, presence: true
end

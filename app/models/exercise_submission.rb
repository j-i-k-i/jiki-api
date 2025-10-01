class ExerciseSubmission < ApplicationRecord
  belongs_to :user_lesson
  has_many :files, -> { order(:filename) },
    class_name: "ExerciseSubmission::File",
    dependent: :destroy,
    inverse_of: :exercise_submission

  validates :uuid, presence: true, uniqueness: true
  validates :user_lesson, presence: true

  delegate :user, :lesson, to: :user_lesson

  def to_param = uuid
end

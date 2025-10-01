class ExerciseSubmission::File < ApplicationRecord
  belongs_to :exercise_submission
  has_one_attached :content

  validates :exercise_submission, presence: true
  validates :filename, presence: true
  validates :digest, presence: true
end

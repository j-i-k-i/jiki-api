FactoryBot.define do
  factory :exercise_submission do
    user_lesson
    uuid { SecureRandom.uuid }
  end
end

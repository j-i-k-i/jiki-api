FactoryBot.define do
  factory :user_lesson do
    user
    lesson
    started_at { Time.current }
  end
end

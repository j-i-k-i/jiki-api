FactoryBot.define do
  factory :user_level do
    user
    level
    started_at { Time.current }
  end
end

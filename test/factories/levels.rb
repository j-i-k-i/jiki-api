FactoryBot.define do
  factory :level do
    sequence(:slug) { |n| "level-#{n}" }
    title { "Level #{slug}" }
    description { "Description for #{title}" }
  end
end

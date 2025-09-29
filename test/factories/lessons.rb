FactoryBot.define do
  factory :lesson do
    level
    sequence(:slug) { |n| "lesson-#{n}" }
    title { "Lesson #{slug}" }
    description { "Description for #{title}" }
    type { "exercise" }
    data { { slug: "basic-movement" } }
  end
end

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { password }
    name { Faker::Name.name }
    locale { "en" }

    trait :hungarian do
      locale { "hu" }
    end

    trait :admin do
      admin { true }
    end
  end
end

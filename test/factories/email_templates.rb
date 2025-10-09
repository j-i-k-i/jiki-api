FactoryBot.define do
  factory :email_template do
    template_type { :level_completion }
    key { "level-1" }
    locale { "en" }
    subject { "Congratulations {{ user.name }}!" }
    body_mjml do
      <<~MJML
        %mj-section{ "background-color": "#ffffff" }
          %mj-column
            %mj-text
              %h1 Congratulations, {{ user.name }}!
            %mj-text
              %p You completed {{ level.title }}!
      MJML
    end
    body_text { "Congratulations, {{ user.name }}! You completed {{ level.title }}!" }

    trait :hungarian do
      locale { "hu" }
      subject { "Gratulálunk {{ user.name }}!" }
      body_mjml do
        <<~MJML
          %mj-section{ "background-color": "#ffffff" }
            %mj-column
              %mj-text
                %h1 Gratulálunk, {{ user.name }}!
              %mj-text
                %p Teljesítetted: {{ level.title }}!
        MJML
      end
      body_text { "Gratulálunk, {{ user.name }}! Teljesítetted: {{ level.title }}!" }
    end
  end
end

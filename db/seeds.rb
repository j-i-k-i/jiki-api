# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a test user
user = User.find_or_create_by!(email: "test@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "Created user: #{user.email}"

# Bootstrap levels from curriculum.json
curriculum_file = File.join(Rails.root, "curriculum.json")
puts "Loading levels from #{curriculum_file}..."

Level::CreateAllFromJson.call(curriculum_file, delete_existing: false)

puts "✓ Successfully loaded levels and lessons!"

# Create some user progress data for testing
puts "\nCreating sample user progress..."

# Get first few levels and lessons
first_level = Level.first
second_level = Level.second

if first_level && second_level
  # Create user_level records
  user_level_1 = UserLevel.find_or_create_by!(user: user, level: first_level) do |ul|
    ul.started_at = 2.days.ago
  end

  user_level_2 = UserLevel.find_or_create_by!(user: user, level: second_level) do |ul|
    ul.started_at = 1.day.ago
  end

  # Create user_lesson records for first level (mix of completed and started)
  first_level.lessons.limit(3).each_with_index do |lesson, index|
    UserLesson.find_or_create_by!(user: user, lesson: lesson) do |ul|
      ul.started_at = 2.days.ago - index.hours
      ul.completed_at = index < 2 ? 2.days.ago - index.hours + 30.minutes : nil
    end
  end

  # Create user_lesson records for second level (only started)
  second_level.lessons.limit(2).each_with_index do |lesson, index|
    UserLesson.find_or_create_by!(user: user, lesson: lesson) do |ul|
      ul.started_at = 1.day.ago - index.hours
    end
  end

  puts "✓ Created sample progress for user #{user.email}"
  puts "  - #{user.user_levels.count} user_levels"
  puts "  - #{user.user_lessons.count} user_lessons (#{user.user_lessons.where.not(completed_at: nil).count} completed)"
end

# Create email templates for level 1 completion
puts "\nCreating email templates for level 1 completion..."

# English template
EmailTemplate.find_or_create_by!(
  template_type: :level_completion,
  key: "level-1",
  locale: "en"
) do |template|
  template.subject = "Congratulations {{ user.name }}! You've completed {{ level.title }}!"
  template.body_mjml = <<~MJML
    %mj-section{ "background-color": "#ffffff" }
      %mj-column
        %mj-text
          %h1{ style: "color: #0066cc; font-size: 28px; font-weight: bold;" } Congratulations, {{ user.name }}!

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            You've just completed <strong>{{ level.title }}</strong> (Level {{ level.position }})!

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            {{ level.description }}

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            This is an incredible milestone in your learning journey. Keep up the amazing work!

        %mj-button{ "href": "https://jiki.io", "background-color": "#0066cc", "color": "#ffffff" }
          Continue Learning

        %mj-text
          %p{ style: "font-size: 14px; color: #666666; margin-top: 20px;" }
            Ready for the next challenge? Log in to continue your progress!
  MJML
  template.body_text = <<~TEXT
    Congratulations, {{ user.name }}!

    You've just completed {{ level.title }} (Level {{ level.position }})!

    {{ level.description }}

    This is an incredible milestone in your learning journey. Keep up the amazing work!

    Continue Learning: https://jiki.io

    Ready for the next challenge? Log in to continue your progress!
  TEXT
end

# Hungarian template
EmailTemplate.find_or_create_by!(
  template_type: :level_completion,
  key: "level-1",
  locale: "hu"
) do |template|
  template.subject = "Gratulálunk {{ user.name }}! Teljesítetted a(z) {{ level.title }} szintet!"
  template.body_mjml = <<~MJML
    %mj-section{ "background-color": "#ffffff" }
      %mj-column
        %mj-text
          %h1{ style: "color: #0066cc; font-size: 28px; font-weight: bold;" } Gratulálunk, {{ user.name }}!

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            Épp most teljesítetted a(z) <strong>{{ level.title }}</strong> szintet ({{ level.position }}. szint)!

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            {{ level.description }}

        %mj-text
          %p{ style: "font-size: 16px; line-height: 24px;" }
            Ez egy hihetetlen mérföldkő a tanulási utadon. Csak így tovább!

        %mj-button{ "href": "https://jiki.io", "background-color": "#0066cc", "color": "#ffffff" }
          Tanulás Folytatása

        %mj-text
          %p{ style: "font-size: 14px; color: #666666; margin-top: 20px;" }
            Készen állsz a következő kihívásra? Jelentkezz be a folytatáshoz!
  MJML
  template.body_text = <<~TEXT
    Gratulálunk, {{ user.name }}!

    Épp most teljesítetted a(z) {{ level.title }} szintet ({{ level.position }}. szint)!

    {{ level.description }}

    Ez egy hihetetlen mérföldkő a tanulási utadon. Csak így tovább!

    Tanulás Folytatása: https://jiki.io

    Készen állsz a következő kihívásra? Jelentkezz be a folytatáshoz!
  TEXT
end

puts "✓ Created email templates for level-1 in English and Hungarian"
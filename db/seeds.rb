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
if Level.any? && Lesson.any?
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
end

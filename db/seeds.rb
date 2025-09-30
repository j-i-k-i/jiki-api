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

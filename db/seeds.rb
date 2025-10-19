# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create an admin user
User.find_or_create_by!(email: "ihid@jiki.io") do |u|
  u.admin = true
  u.password = "password"
  u.password_confirmation = "password"
end
puts "Created admin user"

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
  type: :level_completion,
  slug: Level.first.slug,
  locale: "en"
) do |template|
  template.subject = "Congratulations {{ user.name }}! You've completed {{ level.title }}!"
  template.body_mjml = <<~MJML
    <mj-section background-color="#ffffff">
      <mj-column>
        <mj-text>
          <h1 style="color: #0066cc; font-size: 28px; font-weight: bold;">Congratulations, {{ user.name }}!</h1>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            You've just completed <strong>{{ level.title }}</strong> (Level {{ level.position }})!
          </p>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            {{ level.description }}
          </p>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            This is an incredible milestone in your learning journey. Keep up the amazing work!
          </p>
        </mj-text>

        <mj-button href="https://jiki.io" background-color="#0066cc" color="#ffffff">
          Continue Learning
        </mj-button>

        <mj-text>
          <p style="font-size: 14px; color: #666666; margin-top: 20px;">
            Ready for the next challenge? Log in to continue your progress!
          </p>
        </mj-text>
      </mj-column>
    </mj-section>
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
  type: :level_completion,
  slug: Level.first.slug,
  locale: "hu"
) do |template|
  template.subject = "Gratulálunk {{ user.name }}! Teljesítetted a(z) {{ level.title }} szintet!"
  template.body_mjml = <<~MJML
    <mj-section background-color="#ffffff">
      <mj-column>
        <mj-text>
          <h1 style="color: #0066cc; font-size: 28px; font-weight: bold;">Gratulálunk, {{ user.name }}!</h1>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            Épp most teljesítetted a(z) <strong>{{ level.title }}</strong> szintet ({{ level.position }}. szint)!
          </p>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            {{ level.description }}
          </p>
        </mj-text>

        <mj-text>
          <p style="font-size: 16px; line-height: 24px;">
            Ez egy hihetetlen mérföldkő a tanulási utadon. Csak így tovább!
          </p>
        </mj-text>

        <mj-button href="https://jiki.io" background-color="#0066cc" color="#ffffff">
          Tanulás Folytatása
        </mj-button>

        <mj-text>
          <p style="font-size: 14px; color: #666666; margin-top: 20px;">
            Készen állsz a következő kihívásra? Jelentkezz be a folytatáshoz!
          </p>
        </mj-text>
      </mj-column>
    </mj-section>
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

# Load video production pipelines
puts "\nLoading video production pipelines..."

video_production_seeds_dir = File.join(Rails.root, "db", "seeds", "video_production")

if Dir.exist?(video_production_seeds_dir)
  Dir.glob(File.join(video_production_seeds_dir, "*.json")).each do |file|
    puts "  Loading #{File.basename(file)}..."

    pipeline_data = JSON.parse(File.read(file), symbolize_names: true)

    # Create or update pipeline
    pipeline = VideoProduction::Pipeline.find_or_initialize_by(uuid: pipeline_data[:uuid])
    pipeline.title = pipeline_data[:title]
    pipeline.version = pipeline_data[:version] || "1.0"
    pipeline.config = pipeline_data[:config] || {}
    pipeline.metadata = {
      'totalCost' => 0,
      'estimatedTotalCost' => 0,
      'progress' => {
        'completed' => 0,
        'in_progress' => 0,
        'pending' => pipeline_data[:nodes].length,
        'failed' => 0,
        'total' => pipeline_data[:nodes].length
      }
    }
    pipeline.save!

    # Delete existing nodes for clean slate
    pipeline.nodes.destroy_all

    # Create nodes
    pipeline_data[:nodes].each do |node_data|
      # Assets are immediately available, other nodes need execution
      status = node_data[:type] == 'asset' ? 'completed' : 'pending'

      # Config stays as-is (provider is inside config JSONB)
      config_hash = node_data[:config] || {}

      # For asset nodes with S3 URLs, populate output field
      output = nil
      if node_data[:type] == 'asset' && node_data[:asset] && node_data[:asset][:source]&.start_with?('s3://')
        # Parse S3 URL to extract key (remove s3://bucket/)
        s3_key = node_data[:asset][:source].sub(%r{^s3://[^/]+/}, '')
        output = {
          'type' => node_data[:asset][:type],
          's3Key' => s3_key
        }
      end

      node = pipeline.nodes.create!(
        uuid: node_data[:uuid],
        title: node_data[:title],
        type: node_data[:type],
        inputs: node_data[:inputs] || {},
        config: config_hash,
        asset: node_data[:asset],
        status: status,
        output: output
      )
    end

    puts "    ✓ Created pipeline '#{pipeline.title}' with #{pipeline.nodes.count} nodes"
  end

  puts "✓ Successfully loaded video production pipelines!"
else
  puts "⚠ No video production seeds directory found at #{video_production_seeds_dir}"
end
#!/usr/bin/env ruby
# frozen_string_literal: true

# Bootstrap script to load levels and lessons from curriculum.json
# Usage: ruby scripts/bootstrap_levels.rb [--delete-existing]

require_relative "../config/environment"

# Parse command line arguments
delete_existing = ARGV.include?("--delete-existing")

# Path to curriculum.json (relative to project root)
curriculum_file = File.join(Rails.root, "curriculum.json")

# Run the command
begin
  puts "Loading levels from #{curriculum_file}..."
  puts "Delete existing: #{delete_existing}"

  Level::CreateAllFromJson.call(curriculum_file, delete_existing:)

  puts "✓ Successfully loaded levels and lessons!"
rescue InvalidJsonError => e
  puts "✗ Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "✗ Unexpected error: #{e.message}"
  puts e.backtrace.join("\n")
  exit 1
end
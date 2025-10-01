FactoryBot.define do
  factory :exercise_submission_file, class: "ExerciseSubmission::File" do
    exercise_submission
    filename { "main.rb" }
    digest { XXhash.xxh64("puts 'hello'").to_s }

    after(:create) do |file|
      file.content.attach(
        io: StringIO.new("puts 'hello'"),
        filename: file.filename,
        content_type: 'text/plain'
      )
    end
  end
end

# Exercise Submission Implementation Plan

## Overview
Add exercise submission functionality to allow users to submit code for exercises. Submissions are stored with Active Storage, files are deduplicated using XXHash, and UTF-8 encoding is validated.

## Implementation Steps

### 1. Dependencies
- [ ] Add `gem 'xxhash'` to Gemfile
- [ ] Run `bundle install`

### 2. Database Schema
- [ ] Create migration for `exercise_submissions` table
  - `user_lesson_id` (bigint, foreign key to user_lessons, null: false)
  - `uuid` (string, null: false, indexed, unique)
  - `created_at`, `updated_at` (timestamps)
- [ ] Create migration for `exercise_submission_files` table
  - `exercise_submission_id` (bigint, foreign key, null: false)
  - `filename` (string, null: false)
  - `digest` (string, null: false) - XXHash64 for deduplication
  - `created_at`, `updated_at` (timestamps)
- [ ] Run migrations

### 3. Models
- [ ] Create `ExerciseSubmission` model
  - `belongs_to :user_lesson`
  - `has_many :files, class_name: "ExerciseSubmission::File", dependent: :destroy`
  - Validations: presence of user_lesson, uuid
  - Delegate user and lesson through user_lesson
- [ ] Create `ExerciseSubmission::File` model
  - `belongs_to :exercise_submission`
  - `has_one_attached :content` (Active Storage)
  - Validations: presence of exercise_submission, filename, digest

### 4. Commands
- [ ] Create `ExerciseSubmission::File::Create` command
  - Parameters: `exercise_submission`, `filename`, `content` (string)
  - Sanitize/validate UTF-8 encoding (handle encoding errors gracefully)
  - Calculate XXHash64 digest: `XXhash.xxh64(content).to_s`
  - Create `ExerciseSubmission::File` record
  - Attach content to Active Storage
  - Return created file
- [ ] Create `ExerciseSubmission::Create` command
  - Parameters: `user_lesson`, `files` (array of `{filename:, code:}`)
  - Generate UUID for submission
  - Create `ExerciseSubmission` record
  - Loop through files and call `ExerciseSubmission::File::Create` for each
  - Return created submission

### 5. Controller & Routes
- [ ] Add route: `POST /v1/lessons/:slug/exercise_submissions`
- [ ] Create `V1::ExerciseSubmissionsController`
  - `before_action :use_lesson!` to find lesson by slug
  - `create` action:
    - Find or create `UserLesson` for current_user + @lesson
    - Parse params for files: `[{filename:, code:}]`
    - Call `ExerciseSubmission::Create.(user_lesson, files)`
    - Render serialized submission with 201 status
  - Strong params for files array

### 6. Serializer
- [ ] Create `SerializeExerciseSubmission` serializer
  - Return: `uuid`, `lesson_slug`, `created_at`, `files` array
  - Each file: `filename`, `digest`

### 7. Factories
- [ ] Create `test/factories/exercise_submissions.rb`
  - Factory for `ExerciseSubmission`
  - Association to `user_lesson`
  - Generate UUID
- [ ] Create `test/factories/exercise_submission_files.rb`
  - Factory for `ExerciseSubmission::File`
  - Association to `exercise_submission`
  - Generate filename and digest
  - Attach sample content via Active Storage

### 8. Tests
- [ ] Test `ExerciseSubmission::File::Create` command
  - Creates file with correct attributes
  - Attaches content to Active Storage
  - Calculates correct XXHash64 digest
  - Handles UTF-8 encoding errors gracefully
- [ ] Test `ExerciseSubmission::Create` command
  - Creates submission with UUID
  - Creates all files via File::Create
  - Associates with user_lesson correctly
- [ ] Test `ExerciseSubmission` model
  - Validations
  - Associations
  - Delegates user/lesson correctly
- [ ] Test `ExerciseSubmission::File` model
  - Validations
  - Associations
  - Active Storage attachment
- [ ] Test `V1::ExerciseSubmissionsController`
  - `guard_incorrect_token!` for authentication
  - POST create successfully creates submission
  - POST create finds/creates UserLesson
  - POST create returns correct JSON structure
  - POST create handles invalid lesson slug (404)
- [ ] Test `SerializeExerciseSubmission`
  - Returns correct structure
  - Includes all required fields

### 9. Quality Checks
- [ ] Run tests: `bin/rails test`
- [ ] Run linter: `bin/rubocop`
- [ ] Run security scan: `bin/brakeman`

### 10. Documentation
- [ ] Update `.context/architecture.md` if needed
- [ ] Update `.context/controllers.md` with new controller pattern if needed

## Files to Create/Modify

### New Files
- `db/migrate/YYYYMMDDHHMMSS_create_exercise_submissions.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_exercise_submission_files.rb`
- `app/models/exercise_submission.rb`
- `app/models/exercise_submission/file.rb`
- `app/commands/exercise_submission/create.rb`
- `app/commands/exercise_submission/file/create.rb`
- `app/controllers/v1/exercise_submissions_controller.rb`
- `app/serializers/serialize_exercise_submission.rb`
- `test/factories/exercise_submissions.rb`
- `test/factories/exercise_submission_files.rb`
- `test/commands/exercise_submission/create_test.rb`
- `test/commands/exercise_submission/file/create_test.rb`
- `test/models/exercise_submission_test.rb`
- `test/models/exercise_submission/file_test.rb`
- `test/controllers/v1/exercise_submissions_controller_test.rb`
- `test/serializers/serialize_exercise_submission_test.rb`

### Modified Files
- `Gemfile` - add xxhash gem
- `config/routes.rb` - add exercise_submissions route

# Command Pattern with Mandate

The Jiki API uses the Mandate gem to implement the Command pattern for all business logic. This pattern separates business logic from HTTP concerns and makes the codebase more maintainable and testable.

## Overview

Commands are Ruby objects that encapsulate a single business operation. They live in `app/commands/` and are organized by model that they work from (e.g., `user/`, `lesson/`, `exercise/`).

## Basic Command Structure

(Note: These are all CONCEPTUAL commands - not commands in the codebase).

```ruby
class User::Create
  include Mandate

  initialize_with :params

  def call
    validate!

    User.create!(
      email: params[:email],
      name: params[:name],
      password: params[:password]
    )
  end

  private

  def validate!
    raise ValidationError, errors unless valid?
  end

  memoize
  def valid?
    errors.empty?
  end

  memoize
  def errors
    {}.tap do |errs|
      errs[:email] = ["can't be blank"] if params[:email].blank?
      errs[:name] = ["can't be blank"] if params[:name].blank?
      errs[:password] = ["is too short"] if params[:password].to_s.length < 8
    end
  end
end
```

## Key Concepts

### 1. Initialize With

The `initialize_with` macro defines constructor parameters:

```ruby
# Positional parameters (required)
initialize_with :user, :exercise

# Named parameters with defaults
initialize_with :user, page: 1, per: 20

# Mixed parameters
initialize_with :user, :exercise, force: false
```

### 2. The Call Method

Every command has a single public `call` method that:
- Performs the business operation
- Returns a meaningful value
- Raises exceptions for errors

```ruby
def call
  guard!
  perform_operation!
  result
end
```

### 3. Memoization

Use `memoize` to cache expensive computations:

```ruby
memoize
def user_track
  UserTrack.for(user, exercise.track)
end

memoize
def validation_errors
  # Expensive validation logic
end
```

### 4. Method Naming Conventions

- **Bang methods (`!`)**: For methods that perform actions or can raise exceptions
- **Regular methods**: For computed values or queries

```ruby
private

def validate!  # Performs validation, raises on failure
  raise ValidationError unless valid?
end

def valid?     # Returns a boolean
  errors.empty?
end

def save!      # Performs save, might raise
  record.save!
end

memoize
def record     # Returns a value
  @record ||= User.find(id)
end
```

### 5. Error Handling

Commands raise exceptions rather than returning error states:

```ruby
class ExerciseLockedError < StandardError; end
class ValidationError < StandardError
  attr_reader :errors

  def initialize(errors)
    @errors = errors
    super("Validation failed")
  end
end

# In the command:
def call
  raise ExerciseLockedError unless exercise_unlocked?
  raise ValidationError, validation_errors if validation_errors.any?

  # Proceed with operation
end
```

## Calling Commands

Commands use the `.()` or `.call()` syntax:

```ruby
# In a controller
def create
  user = User::Create.(params)
  render json: { user: SerializeUser.(user) }
rescue ValidationError => e
  render_400(:failed_validations, errors: e.errors)
rescue ExerciseLockedError
  render_403(:exercise_locked)
end

# In tests
test "creates a user" do
  user = User::Create.(email: "test@example.com", name: "Test", password: "password123")
  assert_equal "test@example.com", user.email
end

test "raises on invalid params" do
  assert_raises ValidationError do
    User::Create.(email: "", name: "", password: "")
  end
end
```

## Command Organization

Commands are organized by domain in `app/commands/`:

For example, we might choose to organise like this:

```
app/commands/
├── user/
│   ├── create.rb         # User registration
│   ├── update.rb         # Profile updates
│   ├── authenticate.rb   # Login logic
│   └── reset_password.rb # Password reset
├── lesson/
│   ├── create.rb         # Create new lesson
│   ├── update.rb         # Update lesson content
│   ├── complete.rb       # Mark lesson as complete
│   └── unlock_next.rb    # Unlock next lesson
└── exercise/
    ├── submit.rb         # Submit solution
    ├── evaluate.rb       # Run tests
    ├── complete.rb       # Mark as complete
    └── unlock_hint.rb    # Unlock hints
```

## Common Command Patterns

### Creation Commands

```ruby
class Lesson::Create
  include Mandate

  initialize_with :track, :params

  def call
    validate!

    Lesson.create!(
      track: track,
      title: params[:title],
      content: params[:content],
      position: next_position
    )
  end

  private

  memoize
  def next_position
    track.lessons.maximum(:position).to_i + 1
  end
end
```

### Update Commands

```ruby
class User::Update
  include Mandate

  initialize_with :user, :params

  def call
    validate!
    user.update!(filtered_params)
    user
  end

  private

  def filtered_params
    params.slice(:name, :email, :bio)
  end
end
```

### Query Commands

```ruby
class Exercise::Search
  include Mandate

  initialize_with :user, criteria: nil, page: 1, per: 20

  def call
    base_scope
      .then { |scope| filter_by_criteria(scope) }
      .page(page)
      .per(per)
  end

  private

  def base_scope
    Exercise.accessible_by(user)
  end

  def filter_by_criteria(scope)
    return scope if criteria.blank?
    scope.where("title ILIKE ?", "%#{criteria}%")
  end
end
```

### Processing Commands

```ruby
class Exercise::Submit
  include Mandate

  initialize_with :user, :exercise, :code

  def call
    validate_access!

    submission = create_submission!
    queue_evaluation!(submission)

    submission
  end

  private

  def validate_access!
    raise ExerciseLockedError unless user_can_submit?
  end

  def create_submission!
    Submission.create!(
      user: user,
      exercise: exercise,
      code: code,
      submitted_at: Time.current
    )
  end

  def queue_evaluation!(submission)
    EvaluateSubmissionJob.perform_later(submission)
  end
end
```

## Testing Commands

Commands are tested independently of controllers:

```ruby
require "test_helper"

class User::CreateTest < ActiveSupport::TestCase
  test "creates user with valid params" do
    user = User::Create.(
      email: "test@example.com",
      name: "Test User",
      password: "secure123"
    )

    assert user.persisted?
    assert_equal "test@example.com", user.email
  end

  test "raises ValidationError with invalid email" do
    error = assert_raises ValidationError do
      User::Create.(
        email: "invalid",
        name: "Test",
        password: "secure123"
      )
    end

    assert_includes error.errors[:email], "is invalid"
  end

  test "is idempotent for duplicate emails" do
    params = { email: "test@example.com", name: "Test", password: "secure123" }

    user1 = User::Create.(params)

    assert_raises ActiveRecord::RecordNotUnique do
      User::Create.(params)
    end
  end
end
```

## Best Practices

1. **Keep commands focused**: Each command should do one thing well
2. **Use meaningful exceptions**: Create custom exception classes for domain errors
3. **Validate early**: Run validations at the beginning of `call`
4. **Return meaningful values**: Return the primary object affected by the operation
5. **Use memoization**: Cache expensive queries and computations
6. **Test thoroughly**: Test both success and failure paths
7. **Document complex logic**: Add comments for non-obvious business rules

## Integration with Controllers

Controllers should be thin wrappers that:
1. Call the appropriate command
2. Handle exceptions
3. Render appropriate responses

```ruby
class API::UsersController < ApplicationController
  def create
    user = User::Create.(user_params)
    render json: { user: SerializeUser.(user) }, status: :created
  rescue ValidationError => e
    render_400(:failed_validations, errors: e.errors)
  end

  def update
    user = User::Update.(current_user, user_params)
    render json: { user: SerializeUser.(user) }
  rescue ValidationError => e
    render_400(:failed_validations, errors: e.errors)
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password)
  end
end
```

## When to Use Commands

Use commands for:
- **Business operations**: Creating, updating, deleting records with business logic
- **Complex queries**: When queries involve business rules or multiple steps
- **External integrations**: API calls, payment processing, email sending
- **Multi-step processes**: Operations that coordinate multiple models
- **Validation logic**: Complex validation that goes beyond ActiveRecord validations

Don't use commands for:
- **Simple ActiveRecord operations**: Direct `find`, `where` without business logic
- **Pure data transformations**: Use serializers or presenters instead
- **View logic**: Use helpers or view components
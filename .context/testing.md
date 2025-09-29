# Testing Guide

This document describes the testing approach, framework configuration, and patterns used in the Jiki API.

## Testing Framework

### Minitest
- **Framework**: Ruby's built-in Minitest framework
- **Configuration**: Rails 8 default test setup with API optimizations
- **Parallel Testing**: Enabled by default using `parallelize(workers: :number_of_processors)`
- **Test Environment**: Isolated database with automatic cleanup between tests

### Test Data Management

#### FactoryBot
- **Gem**: `factory_bot_rails` - Object generation library for tests
- **Location**: Factories defined in `test/factories/` directory
- **Syntax**: Full FactoryBot syntax methods available via `include FactoryBot::Syntax::Methods`
- **No Fixtures**: Project uses FactoryBot instead of Rails fixtures for better maintainability

### Mocking and Stubbing

#### Mocha
- **Gem**: `mocha` - Powerful mocking and stubbing framework
- **Usage**: Mock external dependencies and command objects
- **Syntax**: `expects`, `returns`, `raises` for behavior specification

#### WebMock
- **Gem**: `webmock` - HTTP request stubbing library
- **Purpose**: Mock external API calls (Stripe, email services, etc.)
- **Configuration**: Disable network connections except to allowed hosts

#### Factory Organization
```
test/factories/
├── .gitkeep           # Placeholder until first factory is created
├── users.rb           # User factory (when User model exists)
├── lessons.rb         # Lesson factory (when Lesson model exists)
└── exercises.rb       # Exercise factory (when Exercise model exists)
```

#### Factory Patterns
When creating factories, follow these conventions:
- **One factory per model** in appropriately named files
- **Traits** for variations (e.g., `:admin`, `:with_profile`)
- **Sequences** for unique values (emails, handles)
- **Associations** properly defined between related models
- **Realistic test data** that matches business domain

Example factory structure:
```ruby
FactoryBot.define do
  factory :user do
    email { "user-#{SecureRandom.hex(4)}@jiki.dev" }
    name { "Test User" }
    # ... other attributes

    trait :admin do
      role { :admin }
    end

    factory :user_with_progress do
      after(:create) do |user|
        create_list(:lesson_progress, 3, user: user)
      end
    end
  end
end
```

## Test Types

### Unit Tests
- **Location**: `test/models/`, `test/services/`, `test/lib/`
- **Purpose**: Test individual classes and methods in isolation
- **Naming**: `*_test.rb` files with descriptive test method names
- **Assertions**: Use Minitest assertions (`assert_equal`, `assert_raises`, etc.)

### Integration Tests
- **Location**: `test/integration/`
- **Purpose**: Test feature workflows and cross-system interactions
- **Database**: Full database interactions with factory-created test data

### Controller/API Tests
- **Location**: `test/controllers/`
- **Purpose**: Test API endpoints, JSON responses, authentication
- **Helpers**: Use Rails controller test helpers for requests and assertions
- **Response Testing**: Validate JSON structure, status codes, headers

## Database Setup

### Test Database
- **Isolation**: Each test runs in a database transaction (rolled back after)
- **Cleanup**: Automatic cleanup between tests via Rails transactional fixtures
- **Performance**: Fast test execution through transaction-based isolation

### Data Creation
```ruby
# Preferred: Use FactoryBot
user = create(:user, name: "Test User")
users = create_list(:user, 3, :admin)

# For attributes only (no database persistence)
user_attributes = attributes_for(:user)
```

## Running Tests

### Basic Commands
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test method
bin/rails test test/models/user_test.rb -n test_should_validate_email

# Run with verbose output
bin/rails test -v

# Run in parallel (default)
bin/rails test -j 4
```

### Test Categories
```bash
# Run only model tests
bin/rails test test/models/

# Run only controller tests
bin/rails test test/controllers/

# Run only integration tests
bin/rails test test/integration/
```

## Best Practices

### Test Organization
- **One assertion per test** when possible
- **Descriptive test names** that explain the scenario
- **Setup/teardown** using `setup` and `teardown` methods when needed
- **Test isolation** - tests should not depend on each other

### Factory Usage
- **Use `create` for database persistence** when testing database interactions
- **Use `build` for in-memory objects** when database isn't needed
- **Use `attributes_for` for hash attributes** when creating objects manually
- **Create minimal data** - only what's needed for the specific test

### API Testing Patterns

#### Basic Controller Test
```ruby
class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @token = create(:auth_token, user: @user)
    @headers = { 'Authorization' => "Bearer #{@token.token}" }
  end

  test "should get user profile" do
    get user_path(@user), headers: @headers, as: :json

    assert_response :success
    assert_equal @user.name, response.parsed_body['user']['name']
  end

  test "requires authentication" do
    get user_path(@user), as: :json

    assert_response :unauthorized
    assert_equal 'invalid_auth_token', response.parsed_body['error']['type']
  end
end
```

#### Testing Commands in Controllers
```ruby
class LessonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_user  # Helper method to set up authentication
  end

  test "delegates to Lesson::Create command" do
    lesson = build(:lesson)
    Lesson::Create.expects(:call).with(
      @current_user,
      title: "New Lesson",
      content: "Content"
    ).returns(lesson)

    post lessons_path,
      params: { lesson: { title: "New Lesson", content: "Content" } },
      headers: @headers,
      as: :json

    assert_response :created
  end

  test "handles command validation errors" do
    error = ValidationError.new(title: ["can't be blank"])
    Lesson::Create.expects(:call).raises(error)

    post lessons_path,
      params: { lesson: { content: "Content" } },
      headers: @headers,
      as: :json

    assert_response :bad_request
    assert_equal ["can't be blank"], response.parsed_body['error']['errors']['title']
  end
end
```

#### Authentication Testing Helper
```ruby
# In test_helper.rb or a support file
module AuthenticationHelper
  def setup_user(user = nil)
    @current_user = user || create(:user)
    @auth_token = create(:auth_token, user: @current_user)
    @headers = { 'Authorization' => "Bearer #{@auth_token.token}" }
  end

  def auth_headers_for(user)
    token = create(:auth_token, user: user)
    { 'Authorization' => "Bearer #{token.token}" }
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
```

#### Testing Authentication Guards
```ruby
# Macro for testing authentication on all endpoints
class ApplicationControllerTest < ActionDispatch::IntegrationTest
  def self.guard_incorrect_token!(path_helper, args: [], method: :get)
    test "#{method} #{path_helper} returns 401 with invalid token" do
      path = send(path_helper, *args)
      send(method, path, headers: { 'Authorization' => 'Bearer invalid' }, as: :json)

      assert_response :unauthorized
      assert_equal 'invalid_auth_token', response.parsed_body['error']['type']
    end
  end
end

# Usage in controller tests
class ExercisesControllerTest < ApplicationControllerTest
  guard_incorrect_token! :exercises_path
  guard_incorrect_token! :exercise_path, args: [1]
  guard_incorrect_token! :submit_exercise_path, args: [1], method: :post
end
```

### Performance Considerations
- **Minimize database calls** in factory definitions
- **Use traits wisely** to avoid complex factory hierarchies
- **Prefer `build` over `create`** when database persistence isn't required
- **Use `create_list` efficiently** for bulk data creation

## Command Testing

### Testing Mandate Commands

Commands are tested independently from controllers:

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
    assert_equal "Test User", user.name
  end

  test "raises ValidationError with blank email" do
    error = assert_raises ValidationError do
      User::Create.(email: "", name: "Test", password: "secure123")
    end

    assert_includes error.errors[:email], "can't be blank"
  end

  test "is idempotent for creating users" do
    assert_idempotent_command do
      User::Create.(email: "test@example.com", name: "Test", password: "secure123")
    end
  end
end
```

### Mocking with Mocha

```ruby
class Exercise::SubmitTest < ActiveSupport::TestCase
  test "queues evaluation job after submission" do
    user = create(:user)
    exercise = create(:exercise)

    # Mock the job enqueueing
    EvaluateSubmissionJob.expects(:perform_later).once

    submission = Exercise::Submit.(user, exercise, "code")

    assert submission.persisted?
  end

  test "sends notification email on completion" do
    user = create(:user)
    exercise = create(:exercise)

    # Mock the mailer
    ExerciseMailer.expects(:completed).with(user, exercise).returns(mock(deliver_later: true))

    Exercise::Complete.(user, exercise)
  end
end
```

### WebMock Configuration

```ruby
# test/test_helper.rb
require 'webmock/minitest'

# Disable all external connections except allowed hosts
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",  # For system tests if added later
    "127.0.0.1"  # Local services
  ]
)

# Example of stubbing external API calls
class Payment::ProcessTest < ActiveSupport::TestCase
  test "processes Stripe payment successfully" do
    # Stub Stripe API
    stub_request(:post, "https://api.stripe.com/v1/charges")
      .with(
        body: { amount: 1000, currency: "usd", source: "tok_test" },
        headers: { 'Authorization' => 'Bearer sk_test_key' }
      )
      .to_return(
        status: 200,
        body: { id: "ch_123", status: "succeeded" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    charge = Payment::Process.(amount: 1000, token: "tok_test")

    assert_equal "ch_123", charge.stripe_id
    assert_equal "succeeded", charge.status
  end

  test "handles Stripe API errors" do
    stub_request(:post, "https://api.stripe.com/v1/charges")
      .to_return(status: 402, body: { error: { message: "Card declined" } }.to_json)

    assert_raises Payment::CardDeclinedError do
      Payment::Process.(amount: 1000, token: "tok_test")
    end
  end
end
```

## JSON Response Testing

### Custom Assertions

```ruby
# test/support/json_assertions.rb
module JsonAssertions
  def assert_json_response(expected)
    actual = response.parsed_body
    assert_equal expected.deep_stringify_keys, actual
  end

  def assert_json_structure(structure, data = response.parsed_body)
    structure.each do |key, expected_type|
      assert data.key?(key.to_s), "Expected key '#{key}' in JSON response"

      if expected_type.is_a?(Hash)
        assert_json_structure(expected_type, data[key.to_s])
      elsif expected_type.is_a?(Array) && expected_type.first.is_a?(Hash)
        data[key.to_s].each do |item|
          assert_json_structure(expected_type.first, item)
        end
      elsif expected_type
        assert data[key.to_s].is_a?(expected_type),
          "Expected '#{key}' to be #{expected_type}, got #{data[key.to_s].class}"
      end
    end
  end
end

# Usage in tests
class UsersControllerTest < ActionDispatch::IntegrationTest
  include JsonAssertions

  test "returns correct JSON structure" do
    get user_path(@user), headers: @headers, as: :json

    assert_json_structure({
      user: {
        id: Integer,
        email: String,
        name: String,
        created_at: String,
        progress: {
          lessons_completed: Integer,
          exercises_solved: Integer
        }
      }
    })
  end
end
```

## Support Files

### Test Helpers
- **Location**: `test/support/` directory
- **Purpose**: Shared test utilities, custom assertions, helper methods
- **Loading**: Automatically loaded via `test_helper.rb` if needed
- **Examples**: Authentication helpers, custom matchers, API response helpers

### Configuration
- **Test Helper**: Core test configuration in `test/test_helper.rb`
- **Environment**: Test-specific settings in `config/environments/test.rb`
- **Database**: Test database configuration in `config/database.yml`

## Quality Standards

### Before Committing
Always run these commands to ensure test quality:
1. **All tests pass**: `bin/rails test`
2. **Linting passes**: `bin/rubocop`
3. **Security scan clean**: `bin/brakeman`

### Test Coverage Goals
- **High coverage** for models and business logic
- **API endpoints** should have comprehensive request/response tests
- **Critical user flows** covered by integration tests
- **Edge cases and error scenarios** included in test suite

## Future Enhancements

When the codebase grows, consider adding:
- **System/End-to-end tests** using Capybara for complex workflows
- **Performance tests** for API response times
- **Contract tests** for external API integrations
- **Test data builders** for complex domain object creation
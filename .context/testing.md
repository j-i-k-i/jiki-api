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
```ruby
class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get user profile" do
    user = create(:user)

    get api_v1_user_path(user),
        headers: { 'Authorization' => "Bearer #{user.auth_token}" }

    assert_response :success
    assert_equal user.name, response.parsed_body['name']
  end
end
```

### Performance Considerations
- **Minimize database calls** in factory definitions
- **Use traits wisely** to avoid complex factory hierarchies
- **Prefer `build` over `create`** when database persistence isn't required
- **Use `create_list` efficiently** for bulk data creation

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
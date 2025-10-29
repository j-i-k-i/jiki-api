# Command Pattern with Mandate

## Overview

All business logic uses the Mandate gem command pattern. Commands live in `app/commands/` organized by domain (e.g., `user/`, `lesson/`, `concept/`).

## Command Structure

```ruby
class SomeNamespace::Create
  include Mandate

  initialize_with :required_param, optional: 'default'

  def call
    # Only creates/updates/deletes and calls to bang methods
    # All other logic extracted to memoized methods
  end

  private
  memoize
  def computed_value
    # Expensive computation or data transformation
  end
end
```

## Key Patterns

### Call Method
- Contains ONLY primary creates/updates or calls to bang methods
- All other logic extracted to memoized private methods
- Use `.tap` for creation with side effects

### Memoization
- Use `memoize` for expensive computations and data transformations
- Treat memoized methods as "objects masquerading as methods"
- Extract logic from `call` to keep it clean

### Error Handling
- Raise exceptions rather than returning error states
- Global exceptions defined in `config/initializers/exceptions.rb`
- Command-specific exceptions can remain in command class

### Security: SQL LIKE Queries
**ALWAYS sanitize user input before adding wildcards:**
```ruby
# ✅ CORRECT
scope.where("title ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(search)}%")

# ❌ WRONG - Wildcard injection vulnerability
scope.where("title ILIKE ?", "%#{search}%")
```

## Usage

```ruby
# Call syntax
result = SomeCommand.(param1, param2, optional: value)

# In controllers - thin wrappers
def create
  user = User::Create.(params)
  render json: SerializeUser.(user)
rescue ValidationError => e
  render_400(:failed_validations, errors: e.errors)
end
```

## Testing

Test commands independently of controllers:
```ruby
test "creates record" do
  result = SomeCommand.(params)
  assert result.persisted?
end

test "raises on invalid input" do
  assert_raises ValidationError do
    SomeCommand.(invalid_params)
  end
end
```

## When to Use Commands

**Use for:**
- Business operations with logic
- Complex queries with business rules
- Multi-step processes
- External integrations

**Don't use for:**
- Simple ActiveRecord operations without logic
- Pure data transformations (use serializers)
- View logic (use helpers)

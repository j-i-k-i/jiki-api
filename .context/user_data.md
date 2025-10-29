# User::Data Pattern

## Overview

The `User::Data` model follows the Exercism pattern of separating core user authentication/identity data from extended user metadata. This provides better organization and allows for future extensibility.

## Architecture

### Models

#### User::Data (`app/models/user/data.rb`)

- **Purpose**: Stores extended user metadata that doesn't belong in the core `users` table
- **Relationship**: `belongs_to :user` (one-to-one)
- **Creation**: Automatically created when a User is initialized via `after_initialize` callback
- **Access**: Always available via `user.data`

#### User Model Integration

```ruby
# app/models/user.rb
has_one :data, dependent: :destroy, class_name: "User::Data", autosave: true

after_initialize do
  build_data if new_record? && !data
end
```

**Key Features:**
- `autosave: true` - User::Data saves automatically when user saves
- `after_initialize` - Ensures data record always exists for new users
- No need to explicitly create User::Data - handled by framework

### Database Schema

```ruby
# user_data table
user_id (bigint, FK, unique, NOT NULL)
created_at
updated_at
```

**Currently minimal** - designed to be extended as needed with:
- User preferences
- Cached computed values
- Feature flags
- Metadata that changes frequently

## Usage Patterns

### Creating Users

```ruby
# Factory
user = create :user
user.data  # => User::Data record (automatically created)

# Manual creation
user = User.new(email: "test@example.com", ...)
user.data  # => User::Data instance (not yet saved)
user.save  # Saves both user and data (autosave: true)
```

### Accessing User::Data

```ruby
# Direct access
user.data.some_future_field

# Can add delegation if needed
# In User model:
# delegate :some_field, to: :data
```

## Related Patterns

This pattern is consistent with the existing join table pattern for user progression:

- **UserLesson** - Tracks user engagement with lessons
- **UserLevel** - Tracks user engagement with levels
- **UserConcept** - Tracks unlocked concepts (see concept_unlocking.md)

## Future Extensions

The User::Data model can be extended with fields like:

```ruby
# Possible future fields
preferences (jsonb)       # UI/UX preferences
cache (jsonb)             # Computed values (total_lessons_completed, etc.)
settings (jsonb)          # Feature-specific settings
subscription_status (enum)
premium_until (datetime)
locale (string)           # If we want to move from users table
```

## Testing

### Factory

```ruby
user = create :user
assert user.data.present?
```

The factory automatically creates User::Data via the `after_initialize` callback - no explicit setup needed.

### Traits

Add traits to User factory for testing specific User::Data states:

```ruby
trait :with_custom_data do
  after(:create) do |user|
    user.data.update!(some_field: value)
  end
end
```

## References

- **Pattern Source**: Exercism website (`../../exercism/website/app/models/user/data.rb`)
- **Migration**: `db/migrate/XXXXXX_create_user_data.rb`
- **Model**: `app/models/user/data.rb`
- **Related**: `.context/concepts.md` (concept unlocking system)

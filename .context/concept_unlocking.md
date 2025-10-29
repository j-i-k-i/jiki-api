# Concept Unlocking System

## Overview

Concepts are educational content (videos, explanations) that users unlock by completing lessons. This system tracks which concepts each user has unlocked through a join table pattern.

## Architecture

### Database Schema

```ruby
# concepts table
unlocked_by_lesson_id (bigint, nullable, FK to lessons)

# user_concepts table (join table)
user_id (bigint, FK, NOT NULL)
concept_id (bigint, FK, NOT NULL)
created_at
updated_at

# Indexes:
# - [user_id, concept_id] unique
# - concept_id
```

### Model Relationships

#### Concept Model
```ruby
belongs_to :unlocked_by_lesson, class_name: 'Lesson', optional: true
has_many :user_concepts, dependent: :destroy
```

#### Lesson Model
```ruby
has_one :unlocked_concept, class_name: 'Concept', foreign_key: :unlocked_by_lesson_id
```

#### User Model
```ruby
has_many :user_concepts, dependent: :destroy
has_many :concepts, through: :user_concepts
```

#### UserConcept Model
```ruby
belongs_to :user
belongs_to :concept
validates :concept_id, uniqueness: { scope: :user_id }
```

## How It Works

### 1. Lesson Completion Triggers Unlocking

When a user completes a lesson via `UserLesson::Complete`, the system checks if that lesson unlocks a concept:

```ruby
# app/commands/user_lesson/complete.rb
def call
  ActiveRecord::Base.transaction do
    user_lesson.update!(completed_at: Time.current)
    user_level.update!(current_user_lesson: nil)

    # Unlock concept if this lesson unlocks one
    UserConcept::Create.(user, lesson.unlocked_concept) if lesson.unlocked_concept
  end

  user_lesson
end
```

### 2. UserConcept::Create Command

The dedicated command handles creating the unlock record:

```ruby
# app/commands/user_concept/create.rb
class UserConcept::Create
  include Mandate
  initialize_with :user, :concept

  def call
    UserConcept.find_create_or_find_by!(user: user, concept: concept)
  end
end
```

**Key Features:**
- **Idempotent**: Using `find_create_or_find_by!` ensures no duplicates
- **Atomic**: Wrapped in transaction with lesson completion
- **Simple**: Just creates the join table record

### 3. Querying Unlocked Concepts

```ruby
# Check if user has unlocked a concept
user.concepts.exists?(id: concept.id)
UserConcept.exists?(user: user, concept: concept)

# Get all unlocked concepts for user
user.concepts

# Filter unlocked concepts
user.concepts.where("title ILIKE ?", "%string%")

# See which concept a lesson unlocks
lesson.unlocked_concept  # => Concept or nil

# Find lesson that unlocks a concept
concept.unlocked_by_lesson  # => Lesson or nil
```

## Design Decisions

### Why Join Table Instead of Array Column?

**Considered Array Approach:**
```ruby
# user_data table
unlocked_concept_ids :integer[], default: []
```

**Chose Join Table Because:**
- ✅ Consistent with existing patterns (UserLesson, UserLevel)
- ✅ Standard Rails associations work out of the box
- ✅ Easy to add metadata later (unlock_reason, unlocked_at, etc.)
- ✅ Better for complex queries and analytics
- ✅ Familiar pattern for Rails developers

**Trade-off:**
- More rows in database (but manageable at scale with proper indexing)
- For 20M users × 400 concepts (assuming ~50 unlocked per user) = ~1B rows
- With compound index: still performant for lookups

### Why One Lesson Per Concept?

Currently, each concept can only be unlocked by ONE specific lesson (`unlocked_by_lesson_id` FK).

**Could extend to many-to-many if needed:**
```ruby
# Future: lesson_concepts table
lesson_id
concept_id
```

But current requirement is one-to-one, keeping it simple.

### Immutability

Once a concept is unlocked for a user:
- The UserConcept record is never deleted
- Changing curriculum (which lesson unlocks which concept) doesn't affect existing users
- Users never "lose" unlocked concepts

## Testing

### Factories

```ruby
# Create unlocked concept
user = create :user
concept = create :concept
user_concept = create :user_concept, user: user, concept: concept

# Concept unlocked by lesson
lesson = create :lesson
concept = create :concept, unlocked_by_lesson: lesson
```

### Test Patterns

```ruby
# Test unlocking
test "unlocks concept when completing lesson" do
  user = create :user
  concept = create :concept
  lesson = create :lesson
  concept.update!(unlocked_by_lesson: lesson)

  UserLesson::Complete.(user, lesson)

  assert UserConcept.exists?(user: user, concept: concept)
end

# Test idempotency
test "completing lesson twice doesn't create duplicate unlock" do
  # ... (see test/commands/user_lesson/complete_test.rb)
end
```

## Related Patterns

This follows the same join table pattern as:

- **UserLesson** - Tracks lesson engagement (started_at, completed_at)
- **UserLevel** - Tracks level progress (current_user_lesson_id)
- **UserConcept** - Tracks unlocked concepts (new!)

All use:
- `find_create_or_find_by!` for idempotent creation
- Compound unique indexes
- Transaction wrapping for atomic operations
- Mandate commands for business logic

## Future Considerations

### Possible Extensions

1. **Track Unlock Method**
   ```ruby
   # user_concepts table
   unlocked_via (enum: :lesson_completion, :premium_subscription, :admin_grant)
   unlocked_by_lesson_id (FK, nullable)
   ```

2. **Unlock Timestamps for Analytics**
   - Already have `created_at` which serves as unlock timestamp
   - Can add custom `unlocked_at` if needed for timezone handling

3. **Multiple Unlock Paths**
   ```ruby
   # lesson_concepts join table
   lesson_id
   concept_id
   # Concept unlocks when ANY associated lesson completes
   ```

4. **Concept Prerequisites**
   ```ruby
   # concept_prerequisites
   concept_id
   prerequisite_concept_id
   # Must unlock prerequisite before main concept becomes available
   ```

## References

- **Commands**: `app/commands/user_concept/create.rb`
- **Models**: `app/models/user_concept.rb`, `app/models/concept.rb`
- **Tests**: `test/commands/user_concept/create_test.rb`
- **Migration**: `db/migrate/XXXXXX_create_user_concepts.rb`
- **Related**: `.context/user_data.md`, `.context/concepts.md`

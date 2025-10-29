# Concept Unlocking System

## Overview

Concepts are educational content (videos, explanations) that users unlock by completing lessons. This system tracks which concepts each user has unlocked using a PostgreSQL array column for efficient storage at scale.

## Architecture

### Database Schema

```ruby
# concepts table
unlocked_by_lesson_id (bigint, nullable, FK to lessons)

# user_data table
unlocked_concept_ids (bigint[], default: [], NOT NULL)

# Indexes:
# - unlocked_concept_ids (GIN index for fast containment queries)
```

### Model Relationships

#### Concept Model
```ruby
belongs_to :unlocked_by_lesson, class_name: 'Lesson', optional: true
```

#### Lesson Model
```ruby
has_one :unlocked_concept, class_name: 'Concept', foreign_key: :unlocked_by_lesson_id, inverse_of: :unlocked_by_lesson
```

#### User::Data Model
```ruby
# unlocked_concept_ids is a bigint array column
# Accessed via user.data.unlocked_concept_ids
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
    Concept::UnlockForUser.(lesson.unlocked_concept, user) if lesson.unlocked_concept
  end

  user_lesson
end
```

### 2. Concept::UnlockForUser Command

The dedicated command handles adding the concept ID to the user's array:

```ruby
# app/commands/concept/unlock_for_user.rb
class Concept::UnlockForUser
  include Mandate
  initialize_with :concept, :user

  def call
    return if user.data.unlocked_concept_ids.include?(concept.id)

    user.data.unlocked_concept_ids << concept.id
    user.data.save!
  end
end
```

**Key Features:**
- **Idempotent**: Checks `include?` before appending to prevent duplicates
- **Atomic**: Wrapped in transaction with lesson completion
- **Simple**: Just appends to array and saves

### 3. Querying Unlocked Concepts

```ruby
# Check if user has unlocked a concept
user.data.unlocked_concept_ids.include?(concept.id)

# Get all unlocked concepts for user (using IN query with PK index)
Concept.where(id: user.data.unlocked_concept_ids)

# Filter unlocked concepts
Concept.where(id: user.data.unlocked_concept_ids).where("title ILIKE ?", "%string%")

# See which concept a lesson unlocks
lesson.unlocked_concept  # => Concept or nil

# Find lesson that unlocks a concept
concept.unlocked_by_lesson  # => Lesson or nil

# Find users who unlocked a concept (using GIN index)
User.joins(:data).where("? = ANY(user_data.unlocked_concept_ids)", concept.id)
```

## Design Decisions

### Why Array Column Instead of Join Table?

**Storage Efficiency at Scale:**
- For 20M users × 400 concepts (assuming ~50 unlocked per user)
- **Join table**: 1 billion rows (~300GB with indexes)
- **Array column**: 40GB total (99.99% reduction!)

**Query Performance:**
- GIN index enables O(log n) containment queries (`= ANY`)
- Standard `IN (...)` queries with PK index for concept lookups
- Fast for typical array sizes (< 400 items)

**Benefits:**
- ✅ Massive storage savings at scale
- ✅ Fast indexed queries with GIN
- ✅ Immutable unlock history (IDs stay in array forever)
- ✅ Simple data model (no join table complexity)
- ✅ PostgreSQL array features (containment, overlap, etc.)

**Trade-offs:**
- ❌ No foreign key constraints on array values
- ❌ No timestamps for individual unlocks
- ❌ More complex analytics queries (need `unnest`)
- ❌ Can't easily track which lesson unlocked which concept per user

**Decision:** Storage efficiency at 20M user scale outweighs the trade-offs.

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
- The ID is never removed from the array
- Changing curriculum (which lesson unlocks which concept) doesn't affect existing users
- Users never "lose" unlocked concepts

## Testing

### Test Patterns

```ruby
# Test unlocking
test "unlocks concept when completing lesson" do
  user = create :user
  concept = create :concept
  lesson = create :lesson
  concept.update!(unlocked_by_lesson: lesson)

  assert_difference -> { user.data.reload.unlocked_concept_ids.length }, 1 do
    UserLesson::Complete.(user, lesson)
  end

  assert_includes user.data.unlocked_concept_ids, concept.id
end

# Test idempotency
test "concept unlocking is idempotent" do
  # ... (see test/commands/user_lesson/complete_test.rb)
end
```

## PostgreSQL Array Column Details

### Data Type
```sql
CREATE TABLE user_data (
  unlocked_concept_ids bigint[] DEFAULT '{}' NOT NULL
);

CREATE INDEX index_user_data_on_unlocked_concept_ids
  ON user_data USING gin (unlocked_concept_ids);
```

### Query Operators

```sql
-- Check if array contains value
WHERE ? = ANY(unlocked_concept_ids)

-- Check containment
WHERE unlocked_concept_ids @> ARRAY[?]

-- Get all values from arrays (for analytics)
SELECT unnest(unlocked_concept_ids) FROM user_data
```

### ActiveRecord Usage

```ruby
# Append to array
user.data.unlocked_concept_ids << concept.id
user.data.save!

# Check membership
user.data.unlocked_concept_ids.include?(concept.id)

# Filter with IN clause
Concept.where(id: user.data.unlocked_concept_ids)
```

## Future Considerations

### Possible Extensions

1. **Track Unlock Timestamps**
   - Could use `jsonb` with `{concept_id: timestamp}` mapping
   - Trade-off: More complex queries, larger storage

2. **Multiple Unlock Paths**
   ```ruby
   # lesson_concepts join table
   lesson_id
   concept_id
   # Concept unlocks when ANY associated lesson completes
   ```

3. **Concept Prerequisites**
   ```ruby
   # concept_prerequisites
   concept_id
   prerequisite_concept_id
   # Must unlock prerequisite before main concept becomes available
   ```

4. **Analytics Queries**
   ```sql
   -- Count users who unlocked each concept
   SELECT concept_id, COUNT(*) as user_count
   FROM user_data, unnest(unlocked_concept_ids) AS concept_id
   GROUP BY concept_id
   ORDER BY user_count DESC;
   ```

## References

- **Commands**: `app/commands/concept/unlock_for_user.rb`
- **Models**: `app/models/user/data.rb`, `app/models/concept.rb`
- **Tests**: `test/commands/concept/unlock_for_user_test.rb`
- **Migration**: `db/migrate/XXXXXX_create_user_data.rb`
- **Related**: `.context/user_data.md`, `.context/concepts.md`
- **PostgreSQL Array Docs**: https://www.postgresql.org/docs/current/arrays.html
- **GIN Indexes**: https://www.postgresql.org/docs/current/gin-intro.html

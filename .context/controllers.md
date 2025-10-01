# Controllers

This document describes controller patterns and conventions used in the Jiki API.

## Structure

All API controllers are namespaced under `V1` to support versioning:

```
app/controllers/
├── application_controller.rb    # Base controller with shared functionality
└── v1/                          # API version 1
    ├── auth/                    # Devise authentication controllers
    ├── lessons_controller.rb
    ├── levels_controller.rb
    ├── user_lessons_controller.rb
    └── user_levels_controller.rb
```

## ApplicationController

The base controller (`ApplicationController`) provides shared functionality for all API controllers.

### Authentication

All controllers require authentication by default via `before_action :authenticate_user!`.

**Development Mode:** URL-based authentication is available via `?user_id=X` query parameter. See `.context/auth.md` for details.

### Helper Methods

#### `use_lesson!`

Finds a lesson by slug from the `params[:slug]` and assigns it to `@lesson`. Returns 404 with error JSON if not found.

**Usage:**
```ruby
class LessonsController < ApplicationController
  before_action :use_lesson!

  def show
    render json: { lesson: SerializeLesson.(@lesson) }
  end
end
```

**When to use:**
- Any controller action that needs to load a lesson by slug
- Provides consistent error handling for missing lessons
- Sets `@lesson` instance variable for use in the action

**Error Response:**
```json
{
  "error": {
    "type": "not_found",
    "message": "Lesson not found"
  }
}
```

## Controller Conventions

### Response Format

All API responses should be JSON. Use serializers to format data consistently:

```ruby
def index
  levels = Level.all
  render json: { levels: SerializeLevels.(levels) }
end
```

### Error Handling

Use consistent error response format:

```ruby
render json: {
  error: {
    type: "error_type",
    message: "Human-readable message"
  }
}, status: :status_code
```

### Before Actions

Use `before_action` for common setup:
- `before_action :use_lesson!` - Load lesson by slug
- `before_action :authenticate_user!` - Already applied in ApplicationController

### Testing

All controller actions should have tests covering:
- Successful responses with correct data
- Authentication guards (use `guard_incorrect_token!` macro)
- Error cases (404, validation errors, etc.)
- Serializer usage (mock serializers to verify they're called)

See `.context/testing.md` for detailed testing patterns.

## Example Controller

```ruby
module V1
  class LessonsController < ApplicationController
    before_action :use_lesson!

    def show
      render json: {
        lesson: SerializeLesson.(@lesson)
      }
    end
  end
end
```

## Future Patterns

As the API grows, consider adding:
- Rate limiting middleware
- API versioning strategy (already namespaced for V2)
- Request/response logging
- Parameter sanitization helpers

# Controllers

This document describes controller patterns and conventions used in the Jiki API.

## Structure

All API controllers are namespaced under `V1` to support versioning:

```
app/controllers/
├── application_controller.rb    # Base controller with shared functionality
└── v1/                          # API version 1
    ├── admin/                   # Admin-only controllers
    │   ├── base_controller.rb
    │   └── email_templates_controller.rb
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

### Controller Namespacing Pattern

**IMPORTANT:** Always use `class V1::ControllerName` format instead of module wrapping:

```ruby
# CORRECT: Use class V1:: pattern
class V1::LessonsController < ApplicationController
  # ...
end

# INCORRECT: Don't use module wrapping
module V1
  class LessonsController < ApplicationController
    # ...
  end
end
```

**Why this pattern:**
- More concise and readable
- Standard Ruby namespacing convention
- Consistent with Rails best practices
- Easier to refactor and maintain

**For nested namespaces (e.g., auth controllers):**

```ruby
# CORRECT: Use class V1::Auth:: pattern
class V1::Auth::PasswordsController < Devise::PasswordsController
  # ...
end

# INCORRECT: Don't use nested modules
module V1
  module Auth
    class PasswordsController < Devise::PasswordsController
      # ...
    end
  end
end
```

## Paginated Collection Endpoints

For endpoints that return paginated collections, follow this pattern:

**Controller Pattern**:
```ruby
class V1::Admin::ResourcesController < V1::Admin::BaseController
  def index
    resources = Resource::Search.(
      filter1: params[:filter1],
      filter2: params[:filter2],
      page: params[:page],
      per: params[:per]
    )

    render json: SerializePaginatedCollection.(
      resources,
      serializer: SerializeResources
    )
  end
end
```

**Key Points**:
- Use a `Resource::Search` command for filtering and pagination
- Pass all filter and pagination params to the command
- Use `SerializePaginatedCollection` to wrap results with metadata
- Always specify the collection serializer explicitly

**Example**: `V1::Admin::UsersController` (app/controllers/v1/admin/users_controller.rb:1)

## Admin Controllers

Admin controllers provide administrative access to resources and require admin privileges.

### V1::Admin::BaseController

All admin controllers inherit from `V1::Admin::BaseController`, which adds admin authorization on top of authentication.

**Key Features:**
- Inherits from `ApplicationController` (gets authentication automatically)
- Adds `before_action :ensure_admin!` for authorization
- Returns 403 Forbidden if user is not an admin

**Implementation:**
```ruby
class V1::Admin::BaseController < ApplicationController
  before_action :ensure_admin!

  private
  def ensure_admin!
    return if current_user.admin?

    render json: {
      error: {
        type: "forbidden",
        message: "Admin access required"
      }
    }, status: :forbidden
  end
end
```

### Authentication vs Authorization

**Authentication** (ApplicationController):
- Verifies the user is logged in
- Returns 401 Unauthorized if not authenticated
- Handled by Devise's `authenticate_user!`

**Authorization** (Admin::BaseController):
- Verifies the authenticated user has admin privileges
- Returns 403 Forbidden if not an admin
- Handled by custom `ensure_admin!` method

### Admin Controller Example

```ruby
class V1::Admin::EmailTemplatesController < V1::Admin::BaseController
  before_action :set_email_template, only: %i[show update destroy]

  def index
    email_templates = EmailTemplate.all
    render json: {
      email_templates: SerializeEmailTemplates.(email_templates)
    }
  end

  def update
    email_template = EmailTemplate::Update.(@email_template, email_template_params)
    render json: {
      email_template: SerializeEmailTemplate.(email_template)
    }
  end

  private
  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("Email template not found")
  end

  def email_template_params
    params.require(:email_template).permit(:subject, :body_mjml, :body_text)
  end
end
```

### Testing Admin Controllers

Admin controller tests should verify both authentication and authorization:

```ruby
class EmailTemplatesControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    @headers = auth_headers_for(@admin)
  end

  # Test authentication (401)
  guard_incorrect_token! :v1_admin_email_templates_path, method: :get

  # Test authorization (403)
  test "GET index returns 403 for non-admin users" do
    user = create(:user, admin: false)
    headers = auth_headers_for(user)

    get v1_admin_email_templates_path, headers:, as: :json

    assert_response :forbidden
    assert_json_response({
      error: {
        type: "forbidden",
        message: "Admin access required"
      }
    })
  end

  # Test successful admin access (200)
  test "GET index returns templates for admin users" do
    get v1_admin_email_templates_path, headers: @headers, as: :json

    assert_response :success
  end
end
```
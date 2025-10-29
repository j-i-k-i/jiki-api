# Concepts

This document describes the Concept model and its role in the Jiki learning platform.

## Purpose

Concepts represent fundamental programming topics that students learn throughout the curriculum. Each concept has educational content (markdown-based), optional video resources, and is used to organize and explain core programming ideas.

## Model Structure

### Database Schema

**Table**: `concepts`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | integer | Primary key | Auto-incrementing ID |
| `title` | string | NOT NULL | Concept name (e.g., "Strings", "Arrays") |
| `slug` | string | NOT NULL, UNIQUE | URL-friendly identifier |
| `description` | text | NOT NULL | Brief 1-2 sentence overview |
| `content_markdown` | text | NOT NULL | Full educational content in Markdown |
| `content_html` | text | NOT NULL | Auto-generated HTML from markdown |
| `standard_video_provider` | string | NULL | Video platform for free users ("youtube" or "mux") |
| `standard_video_id` | string | NULL | Video ID for standard tier |
| `premium_video_provider` | string | NULL | Video platform for premium users ("youtube" or "mux") |
| `premium_video_id` | string | NULL | Video ID for premium tier |
| `created_at` | datetime | NOT NULL | Timestamp |
| `updated_at` | datetime | NOT NULL | Timestamp |

**Indexes**:
- Unique index on `slug`

### Model: `app/models/concept.rb`

**Validations**:
- `title`: Required
- `slug`: Required, unique
- `description`: Required
- `content_markdown`: Required
- `standard_video_provider`: Must be "youtube" or "mux" (if present)
- `premium_video_provider`: Must be "youtube" or "mux" (if present)

**Callbacks**:
- `before_validation :generate_slug, on: :create` - Auto-generates kebab-case slug from title if not provided
- `before_save :parse_markdown, if: :content_markdown_changed?` - Converts markdown to HTML when content changes

**Methods**:
- `to_param` - Returns slug for URL generation

## Markdown Processing

### Utils::Markdown::Parse Command

**Location**: `app/commands/utils/markdown/parse.rb`

**Purpose**: Converts Markdown to sanitized HTML

**Dependencies**:
- `commonmarker` (~> 1.0) - GitHub Flavored Markdown parser
- `loofah` (~> 2.22) - HTML sanitization

**Features**:
- Converts GitHub Flavored Markdown to HTML
- Removes HTML comments for security
- Sanitizes output to prevent XSS attacks
- Supports smart punctuation
- Syntax highlighting for code blocks
- Memoized for performance

**Usage**:
```ruby
html = Utils::Markdown::Parse.("# Hello\n\nWorld")
# => "<h1>Hello</h1>\n<p>World</p>"
```

**Extensibility**: Built on CommonMarker's extensible rendering system. Future enhancements can be added by customizing the rendering pipeline.

## Video Provider Integration

Concepts support two tiers of video content:

### Standard Videos (Free Users)
- `standard_video_provider`: Platform hosting the video
- `standard_video_id`: Video identifier on that platform

### Premium Videos (Paid Users)
- `premium_video_provider`: Platform hosting the video
- `premium_video_id`: Video identifier on that platform

### Supported Providers
- **youtube**: YouTube videos
- **mux**: Mux video platform

## Admin API Endpoints

All concept management is done through admin-only endpoints.

### Routes

**Namespace**: `v1/admin/concepts`

| Method | Path | Action | Description |
|--------|------|--------|-------------|
| GET | `/v1/admin/concepts` | index | List all concepts (paginated, searchable) |
| POST | `/v1/admin/concepts` | create | Create new concept |
| GET | `/v1/admin/concepts/:id` | show | Show concept by slug (includes markdown) |
| PATCH | `/v1/admin/concepts/:id` | update | Update concept by slug |
| DELETE | `/v1/admin/concepts/:id` | destroy | Delete concept by slug |

**Note**: The `:id` parameter accepts slugs (e.g., `/v1/admin/concepts/strings`)

### Controller: `app/controllers/v1/admin/concepts_controller.rb`

**Authorization**: Requires admin privileges (inherits from `V1::Admin::BaseController`)

**Search/Filtering** (`index` action):
- `title`: Partial, case-insensitive title search
- `page`: Page number for pagination (default: 1)
- `per`: Results per page (default: 24)

**Response Format**:
- Uses `SerializePaginatedCollection` for index
- Returns `content_markdown` (NOT `content_html`) in admin responses
- Collection serializer excludes `content_markdown` to reduce payload size

## Commands

### Concept::Search

**Purpose**: Search and paginate concepts for admin listing

**Parameters**:
- `title` (optional): Filter by title (partial match, case-insensitive)
- `page` (optional): Page number (default: 1)
- `per` (optional): Results per page (default: 24)

**Returns**: Kaminari-paginated collection

### Concept::Create

**Purpose**: Create a new concept with validation

**Parameters**:
- `attributes`: Hash of concept attributes

**Returns**: Created concept

**Raises**: `ActiveRecord::RecordInvalid` on validation failure

### Concept::Update

**Purpose**: Update an existing concept with validation

**Parameters**:
- `concept`: Concept instance to update
- `attributes`: Hash of attributes to update

**Returns**: Updated concept

**Raises**: `ActiveRecord::RecordInvalid` on validation failure

## Serializers

### SerializeAdminConcept

**Purpose**: Serialize a single concept for admin view/edit

**Includes**:
- All concept fields
- `content_markdown` (for editing)
- Does NOT include `content_html` (generated on save)

### SerializeAdminConcepts

**Purpose**: Serialize concepts for admin list view

**Includes**:
- Basic fields (id, title, slug, description)
- Video provider information
- Does NOT include `content_markdown` (too large for lists)

## Usage Examples

### Creating a Concept

```ruby
Concept::Create.({
  title: "Strings",
  description: "Learn about text manipulation in programming",
  content_markdown: "# Strings\n\nStrings are sequences of characters...",
  standard_video_provider: "youtube",
  standard_video_id: "abc123"
})
```

### Searching Concepts

```ruby
# Search by title
concepts = Concept::Search.(title: "String", page: 1, per: 10)

# Get all concepts
concepts = Concept::Search.()
```

### Updating Content

```ruby
concept = Concept.find_by!(slug: "strings")
Concept::Update.(concept, {
  content_markdown: "# Updated Content\n\nNew information..."
})
# content_html is automatically regenerated
```

## Testing

**Test Coverage**: Complete 1-1 mapping for all components

- Model: `test/models/concept_test.rb`
- Commands: `test/commands/concept/*_test.rb`
- Markdown Parser: `test/commands/utils/markdown/parse_test.rb`
- Controller: `test/controllers/v1/admin/concepts_controller_test.rb`
- Factory: `test/factories/concepts.rb`

## Design Decisions

### Why Separate Markdown and HTML Fields?

- **Performance**: Pre-rendered HTML avoids parsing on every request
- **Consistency**: HTML is generated once and guaranteed to match markdown
- **Audit Trail**: Markdown is the source of truth, easily diffable in version control

### Why Slug-Based URLs for Admin?

- **Consistency**: Matches public-facing API patterns
- **Readability**: URLs like `/admin/concepts/strings` are more meaningful than `/admin/concepts/42`
- **Stability**: Slugs don't change when content is reorganized

### Why Two Video Tiers?

- **Business Model**: Supports freemium model with premium content
- **Flexibility**: Different videos can be used for different user tiers
- **Quality Options**: Premium users might get higher quality or longer videos

## Future Enhancements

Potential additions to the Concept system:

- **Prerequisites**: Link concepts to show learning dependencies
- **Exercises**: Associate practice exercises with concepts
- **User Progress**: Track which concepts users have completed
- **Related Concepts**: Cross-reference related topics
- **Difficulty Levels**: Categorize concepts by complexity
- **Tags**: Flexible categorization beyond single title

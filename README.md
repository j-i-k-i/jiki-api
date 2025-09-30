# Jiki API

Rails 8 API-only application that serves as the backend for Jiki, a Learn to Code platform.

This files contains:
- API Endpoints
- Setup Instructions
- Development Instructions
- Testing Instructions
- Additional Context

---

## API Endpoints

All endpoints require authentication via Bearer token in the `Authorization` header (except authentication endpoints).

### Authentication

- **POST** `/v1/auth/signup` - Register a new user
  - **Params (required):** `email`, `password`, `password_confirmation`
  - **Response:** JWT token in `Authorization` header

- **POST** `/v1/auth/login` - Sign in and receive JWT token
  - **Params (required):** `email`, `password`
  - **Response:** JWT token in `Authorization` header

- **DELETE** `/v1/auth/logout` - Sign out (invalidate token)
  - **Response:** 204 No Content

- **POST** `/v1/auth/password` - Request password reset
  - **Params (required):** `email`
  - **Response:** 200 OK

### Levels

- **GET** `/v1/levels` - Get all levels with nested lessons
  - **Response:**
    ```json
    {
      "levels": [Level, Level, ...]
    }
    ```

### User Levels

- **GET** `/v1/user_levels` - Get current user's levels with progress
  - **Response:**
    ```json
    {
      "user_levels": [UserLevel, UserLevel, ...]
    }
    ```

### User Lessons

- **POST** `/v1/user_lessons/:slug/start` - Start a lesson
  - **Params (required):** `slug` (in URL)
  - **Response:** `{}`

- **PATCH** `/v1/user_lessons/:slug/complete` - Complete a lesson
  - **Params (required):** `slug` (in URL)
  - **Response:** `{}`

---

## Serializers

All API responses use serializers to format data consistently. Below are the data shapes for each serializer.

### Lesson

```json
{
  "slug": "hello-world",
  "type": "exercise",
  "data": {
    "slug": "basic-movement"
  }
}
```

### Level

```json
{
  "slug": "basics",
  "lessons": [Lesson, Lesson, ...]
}
```

### UserLesson

```json
{
  "lesson_slug": "hello-world",
  "status": "started|completed"
}
```

### UserLevel

```json
{
  "level_slug": "basics",
  "user_lessons": [UserLesson, UserLesson, ...]
}
```

---

## Ruby Version

Ruby 3.4.4

## Setup

### Prerequisites

- Ruby 3.4.4 (see `.ruby-version`)
- PostgreSQL
- Bundler

### Installation

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Set up the database:**
   ```bash
   # Create, load schema, and seed with user and curriculum data
   bin/rails db:setup
   ```

3. **Reset curriculum data (optional):**
   ```bash
   # Delete and reload all levels and lessons from curriculum.json
   ruby scripts/bootstrap_levels.rb --delete-existing
   ```

## Development

### Starting the Server

```bash
bin/dev
```

The server runs on port 3061 by default.

## Tests

### Running Tests

```bash
bin/rails test
```

### Linting

```bash
bin/rubocop
```

### Security Checks

```bash
bin/brakeman
```

## Additional Documentation

For detailed development guidelines, architecture decisions, and patterns, see the `.context/` directory:
- `.context/README.md` - Overview and index of all context files
- `.context/commands.md` - Development commands reference
- `.context/architecture.md` - Rails API structure and patterns
- `.context/testing.md` - Testing guidelines and FactoryBot usage

See `CLAUDE.md` for AI assistant guidelines.

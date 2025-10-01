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

See Serializers below for Lesson, UserLesson, etc. 
These should have equivelent fe types.

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

- **GET** `/v1/levels` - Get all levels with nested lessons (basic info only)
  - **Response:**
    ```json
    {
      "levels": [Level, Level, ...]
    }
    ```

### Lessons

- **GET** `/v1/lessons/:slug` - Get a single lesson with full data
  - **Params (required):** `slug` (in URL)
  - **Response:**
    ```json
    {
      "lesson": Lesson
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

- **GET** `/v1/user_lessons/:lesson_slug` - Get user's progress on a specific lesson
  - **Params (required):** `lesson_slug` (in URL)
  - **Response:**
    ```json
    {
      "user_lesson": UserLesson
    }
    ```
  - **Error:** Returns 404 if user hasn't started the lesson

- **POST** `/v1/user_lessons/:lesson_slug/start` - Start a lesson
  - **Params (required):** `lesson_slug` (in URL)
  - **Response:** `{}`

- **PATCH** `/v1/user_lessons/:lesson_slug/complete` - Complete a lesson
  - **Params (required):** `lesson_slug` (in URL)
  - **Response:** `{}`

### Exercise Submissions

- **POST** `/v1/lessons/:slug/exercise_submissions` - Submit code for an exercise
  - **Params (required):** `slug` (in URL), `submission` (object with `files` array)
  - **Request Body:**
    ```json
    {
      "submission": {
        "files": [
          {"filename": "main.rb", "code": "puts 'hello'"},
          {"filename": "helper.rb", "code": "def help\nend"}
        ]
      }
    }
    ```
  - **Response:** `{}`
  - **Notes:**
    - Files are stored using Active Storage
    - Each file gets a digest calculated using XXHash64 for deduplication
    - UTF-8 encoding is automatically sanitized
    - Creates or updates the UserLesson for the current user

---

## Serializers

All API responses use serializers to format data consistently. Below are the data shapes for each serializer.

### Level

```json
{
  "slug": "basics",
  "lessons": [
    {
      "slug": "hello-world",
      "type": "exercise"
    },
    ...
  ]
}
```

**Note:** Level serialization only includes basic lesson info (slug and type). Use `GET /v1/lessons/:slug` to fetch full lesson data including the `data` field.

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

### UserLesson

The UserLesson serializer returns different data based on the lesson type:

**Non-exercise lesson (tutorial, video, etc.):**
```json
{
  "lesson_slug": "intro-tutorial",
  "status": "started|completed",
  "data": {}
}
```

**Exercise lesson with submission:**
```json
{
  "lesson_slug": "hello-world",
  "status": "completed",
  "data": {
    "last_submission": {
      "uuid": "abc-123",
      "files": [
        {
          "filename": "solution.rb",
          "content": "puts 'Hello World'"
        }
      ]
    }
  }
}
```

**Exercise lesson without submission:**
```json
{
  "lesson_slug": "hello-world",
  "status": "started",
  "data": {
    "last_submission": null
  }
}
```

### UserLevel

The UserLevel serializer inlines lesson data for optimal query performance:

```json
{
  "level_slug": "basics",
  "user_lessons": [
    {
      "lesson_slug": "hello-world",
      "status": "completed"
    },
    {
      "lesson_slug": "variables",
      "status": "started"
    }
  ]
}
```

**Note:** UserLevel only includes basic lesson progress (slug and status). Use `GET /v1/user_lessons/:lesson_slug` to fetch detailed progress including submission data.

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
- `.context/controllers.md` - Controller patterns and helper methods
- `.context/testing.md` - Testing guidelines and FactoryBot usage

See `CLAUDE.md` for AI assistant guidelines.

---

Copyright (c) 2025 Jiki Ltd. All rights reserved.

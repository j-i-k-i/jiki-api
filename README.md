# Jiki API

Rails 8 API-only application that serves as the backend for Jiki, a Learn to Code platform.

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

The server runs on port 3061.

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

# Development Commands

## Core Commands

### Development Setup
```bash
# Initial setup (installs dependencies, creates DB, starts server)
bin/setup

# Start development server
bin/dev  # or: bin/rails server

# Console access
bin/rails console         # Interactive Ruby console with app loaded
```

### Database Operations
```bash
bin/rails db:create       # Create databases
bin/rails db:migrate      # Run migrations
bin/rails db:prepare      # Setup or migrate as needed
bin/rails db:reset        # Drop, recreate, and seed
bin/rails db:seed         # Load seed data
```

## Testing Commands

### Running Tests
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test by name
bin/rails test test/models/user_test.rb -n test_should_validate_email

# Run tests in parallel (default)
bin/rails test -j 4

# Run tests with verbose output
bin/rails test -v
```

## Code Quality Commands

### Linting & Security
```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -A

# Auto-fix safe issues only
bin/rubocop -a

# Security scan
bin/brakeman

# Check specific paths
bin/rubocop app/controllers
```

## Docker Commands

### Production Build
```bash
# Build production image
docker build -t jiki-api .

# Run container (requires master key)
docker run -d -p 3000:80 -e RAILS_MASTER_KEY=<key> --name jiki-api jiki-api

# View container logs
docker logs jiki-api

# Shell into running container
docker exec -it jiki-api /bin/bash
```

## Rails Generators

### Common Generators
```bash
# Generate model
bin/rails generate model User email:string name:string

# Generate controller
bin/rails generate controller api/v1/users

# Generate migration
bin/rails generate migration AddIndexToUsers

# Destroy generated files (rollback)
bin/rails destroy model User
```

## Asset & Cache Management

```bash
# Clear logs and temp files
bin/rails log:clear tmp:clear

# Clear Rails cache
bin/rails tmp:cache:clear

# Restart app (touch restart file)
bin/rails restart
```

## Routes & Middleware

```bash
# Show all routes
bin/rails routes

# Show routes for specific controller
bin/rails routes -c users

# Show routes matching pattern
bin/rails routes -g user

# Show middleware stack
bin/rails middleware
```
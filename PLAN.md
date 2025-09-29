# Devise + JWT Authentication Implementation Plan

## Phase 1: Documentation ✅
- [x] Create comprehensive auth documentation in `.context/auth.md`

## Phase 2: Setup & Configuration
- [x] Create feature branch `feature/auth-setup`
- [x] Add Devise and JWT gems to Gemfile
- [x] Run bundle install
- [x] Run `rails generate devise:install`
- [x] Configure Devise for API-only mode in initializer
- [x] Add JWT configuration to Devise initializer
- [x] Configure Rails credentials for JWT secret

## Phase 3: User Model
- [x] Generate User model with Devise
- [x] Add JTI field for JWT revocation
- [x] Add name field for user profiles
- [x] Run migrations

## Phase 4: JWT Configuration
- [x] Install and configure devise-jwt revocation strategy
- [x] Set up JWT dispatch and revocation paths
- [x] Configure token expiration (30 days)
- [x] Add JWT secret to credentials

## Phase 5: Custom Controllers
- [x] Create `Api::V1::Auth::RegistrationsController`
- [x] Create `Api::V1::Auth::SessionsController`
- [x] Create `Api::V1::Auth::PasswordsController`
- [x] Ensure all controllers return JSON responses
- [x] Handle authorization header for JWT tokens

## Phase 6: Routing & Configuration
- [x] Set up routes under `/api/v1/auth/*`
- [x] Configure CORS in `config/initializers/cors.rb`
- [x] Configure mailer default URL options
- [ ] Create custom mailer for frontend password reset URLs

## Phase 7: Testing Infrastructure
- [x] Create User factory with FactoryBot
- [x] Create authentication helper for tests
- [x] Write unit tests for User model
  - [x] Validation tests
  - [x] Authentication tests
  - [x] Token generation tests
- [x] Write API controller tests
  - [x] Registration endpoint tests
  - [x] Login endpoint tests
  - [x] Logout endpoint tests
  - [x] Password reset request tests
  - [x] Password reset completion tests
  - [x] Authentication guard tests

## Phase 8: Quality Assurance
- [ ] Run all tests: `bin/rails test`
- [ ] Run RuboCop: `bin/rubocop`
- [ ] Fix any RuboCop issues
- [ ] Run Brakeman: `bin/brakeman`
- [ ] Address any security concerns
- [ ] Manual testing with curl commands

## Phase 9: Git Workflow
- [ ] Review all changes
- [ ] Commit with descriptive message
- [ ] Push feature branch to remote
- [ ] Create pull request with comprehensive description

## Testing Commands

### Registration Test
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123","password_confirmation":"password123","name":"Test User"}}'
```

### Login Test
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'
```

### Authenticated Request Test
```bash
curl -X GET http://localhost:3000/api/v1/profile \
  -H "Authorization: Bearer <jwt_token>"
```

## Notes

- Using devise-jwt with JTIMatcher revocation strategy for simplicity
- OAuth fields added to User model for future implementation
- Password reset emails will link to frontend URL (configured via environment variable)
- All endpoints return JSON with consistent error format as per `.context/api.md`
- Tests follow patterns from `.context/testing.md`
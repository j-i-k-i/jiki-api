# Context Files

This directory contains documentation that provides context to AI assistants when working with the Jiki API codebase. These files serve as a knowledge base to help maintain consistency, understand architecture decisions, and follow established patterns.

## Purpose

Context files help AI assistants:
- Understand the Rails API architecture and patterns
- Follow established coding conventions
- Make informed decisions about implementation approaches
- Maintain consistency with existing code
- Avoid common pitfalls and anti-patterns

## Directory Structure

### Core Context Files

- **[commands.md](./commands.md)** - Development commands, testing, linting, and Docker operations
- **[architecture.md](./architecture.md)** - Rails API structure, components, and design patterns
- **[configuration.md](./configuration.md)** - Environment variables, CORS, storage, and deployment config
- **[testing.md](./testing.md)** - Testing framework, FactoryBot setup, and testing patterns

## How to Use These Files

### For AI Assistants

1. **Start here** - Read this README first to understand available documentation
2. **Commands** - Check `commands.md` for how to run tests, lint, and perform common tasks
3. **Architecture** - Review `architecture.md` before making structural changes
4. **Configuration** - Consult `configuration.md` when setting up new services or environments
5. **Testing** - Reference `testing.md` for FactoryBot patterns, test organization, and quality standards

### When to Update

Update context files when:
- Adding new architectural patterns or components
- Changing configuration approaches
- Discovering important implementation details
- Learning from mistakes that should be avoided

## Related Repositories

This API works in conjunction with:
- **Frontend** (`../fe`) - React/Next.js application
- **Curriculum** (`../curriculum`) - Learning content and exercises
- **Interpreters** (`../interpreters`) - Code execution engines
- **Overview** (`../overview`) - Business requirements and system design

## Key Principles

### Documentation is Current State
All documentation should reflect the current state of the codebase. Never use changelog format or document iterative changes. Focus on what IS, not what WAS.

### Keep It Relevant
Don't duplicate code that's easily accessible. Reference file paths and describe functionality instead of copying large code blocks.

### Continuous Improvement
When you learn something important or encounter a pattern worth documenting, update the relevant context file immediately.

## Testing & Quality Standards

### Before Committing
Always run these checks before committing code:
1. **Tests**: `bin/rails test`
2. **Linting**: `bin/rubocop`
3. **Type checking**: If TypeScript is added later
4. **Security**: `bin/brakeman`

### Context File Maintenance
Before committing, review if any context files need updating based on your changes:
- New commands added? Update `commands.md`
- Architecture changed? Update `architecture.md`
- Configuration modified? Update `configuration.md`

## Development Workflow

1. Read relevant context files before starting work
2. Make changes following established patterns
3. Run all tests and linting
4. Update context files if needed
5. Commit with clear, descriptive messages

## Rails-Specific Guidelines

### API-Only Considerations
- No views or asset pipeline
- JSON responses only
- Middleware optimized for APIs
- CORS configuration required

### Testing with Minitest and FactoryBot
- Parallel execution by default
- FactoryBot for test data generation (no fixtures)
- Test files in `test/` directory with factories in `test/factories/`
- Run specific tests with `-n` flag

### Background Jobs
- Use Active Job for async processing
- Configure queue adapter per environment
- Monitor job performance in production

## Security Notes

### Sensitive Information
- Never commit `config/master.key`
- Use Rails credentials for secrets
- Filter sensitive parameters from logs
- Validate all input data

### API Security
- Implement rate limiting
- Use strong authentication (JWT planned)
- Validate CORS origins
- Sanitize error messages in production
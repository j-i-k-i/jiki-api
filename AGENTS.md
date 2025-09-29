# AGENTS.md

This file provides guidance to Agents (e.g. Claude Code) when working with code in this repository.

## How to work in this project

### Context for Agents

There is a `.context` folder, which contains files explaining how everything in this project works.
You should read any files relevant to the task you are asked to work on.
Start by running:

```bash
cat .context/README.md
```

### Related Repositories

This repo is part of a set of repos:
- **Frontend** (`../fe`) - React/Next.js application
- **Curriculum** (`../curriculum`) - Learning content and exercises
- **Interpreters** (`../interpreters`) - Code execution engines
- **Overview** (`../overview`) - Business requirements and system design

You can look into those repos if you need to understand how they integrate with this API.

## Project Context

This is the Jiki API - a Rails 8 API-only application that serves as the backend for Jiki, a Learn to Code platform. Jiki provides structured, linear learning pathways for coding beginners through problem-solving and interactive exercises.

## Core Business Requirements

Based on `/overview/tech/backend.md`:
- **Linear Learning Path**: Users progress through lessons sequentially
- **Exercise State Management**: Server stores all exercise submissions and progress
- **PPP Pricing**: Geographic-based pricing with Stripe integration
- **Internationalization**: Database-stored translations generated to i18n files
- **Integration with Exercism**: Shares infrastructure patterns but different user journey

## Before Committing

Always perform these checks before committing code:

1. **Run Tests**: `bin/rails test`
2. **Run Linting**: `bin/rubocop`
3. **Security Check**: `bin/brakeman`
4. **Update Context Files**: Review if any `.context/` files need updating based on your changes
5. **Commit Message**: Use clear, descriptive commit messages that explain the "why"

## Quick Reference

For detailed information, see the context files:
- **Commands**: `.context/commands.md` - All development, testing, and deployment commands
- **Architecture**: `.context/architecture.md` - Rails API structure and design patterns
- **Configuration**: `.context/configuration.md` - Environment variables, CORS, storage setup

## Next Implementation Priorities

Based on business requirements, these features need implementation:
1. User model with progression tracking
2. Lesson/Exercise models with state management
3. JWT authentication
4. API versioning (controllers/api/v1/)
5. CORS configuration for frontend
6. Stripe integration for PPP pricing
7. I18n database storage and file generation
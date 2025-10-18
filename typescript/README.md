# @jiki/api-types

Auto-generated TypeScript types from Jiki Rails API schemas.

**⚠️ DO NOT EDIT FILES IN THIS PACKAGE MANUALLY**

All types are generated from Rails model schemas and constants.

## Usage

### In code-videos

```typescript
import type { TalkingHeadInputs, MergeVideosInputs } from '@jiki/api-types';
```

### In front-end

```typescript
import type { User, Course, Lesson } from '@jiki/api-types';
```

## Regenerating Types

```bash
cd api
bundle exec rake typescript:generate
```

## Publishing to npm (optional)

```bash
cd typescript
npm version patch  # or minor/major
npm publish
```

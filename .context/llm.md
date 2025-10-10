# LLM Integration

## Overview

Jiki uses an LLM proxy service to handle AI-powered translations via Google Gemini. The system follows an async callback pattern for non-blocking operations.

## Architecture

```
Rails API (EmailTemplate::TranslateToLocale)
  → LLM::Exec command
    → HTTP POST to LLM Proxy (Node.js on port 3064)
      → Returns 202 Accepted immediately
      → Gemini API (async)
        → Response streamed back
        → Callback POST to Rails SPI endpoint
          → Updates EmailTemplate record
```

## Components

### LLM Proxy Service

**Location**: `/Users/iHiD/Code/jiki/llm-proxy`

**Purpose**: Separate Node.js service that handles LLM API calls and callbacks

**Key Features**:
- Express server on port 3064
- Google Gemini API integration
- Redis streaming support (future real-time updates)
- Async callback mechanism
- Error handling for rate limits and safety triggers

**Starting the proxy**:
```bash
cd ../llm-proxy
./bin/dev
```

### Rails API Components

#### LLM::Exec Command

**File**: `app/commands/llm/exec.rb`

**Purpose**: HTTP client to call the LLM proxy service

**Usage**:
```ruby
LLM::Exec.(
  :gemini,                    # service
  :flash,                     # model (flash or pro)
  prompt,                     # prompt text
  'email_translation',        # SPI endpoint for callback
  email_template_id: 123      # additional params passed to callback
)
```

**Configuration**:
- Uses `Jiki.config.llm_proxy_url` (default: `http://localhost:3064/exec`)
- 10 second timeout for initial 202 response
- Raises error if proxy is unavailable

#### EmailTemplate::TranslateToLocale

**File**: `app/commands/email_template/translate_to_locale.rb`

**Purpose**: Translate a single email template to a target locale

**Features**:
- Creates placeholder template immediately
- Sends translation prompt to LLM proxy
- Validates source is English, target is supported locale
- Builds comprehensive translation prompt with context

**Usage**:
```ruby
source_template = EmailTemplate.find_for(:level_completion, "basics-1", "en")
EmailTemplate::TranslateToLocale.(source_template, "hu")
```

**Translation Prompt**:
- Localization expert persona
- Clear rules (preserve MJML, maintain tone, keep length)
- Context about template type and slug
- Shows all three fields (subject, body_mjml, body_text)
- Requests JSON response

#### EmailTemplate::TranslateToAllLocales

**File**: `app/commands/email_template/translate_to_all_locales.rb`

**Purpose**: Batch translate template to all supported locales

**Features**:
- Queues background jobs for each locale
- Uses Sidekiq via Mandate's `.defer()` method
- Validates source template is English

**Usage**:
```ruby
source_template = EmailTemplate.find_for(:level_completion, "basics-1", "en")
EmailTemplate::TranslateToAllLocales.(source_template)
```

### SPI (Service Provider Interface)

**Purpose**: Endpoints for external services to send callbacks

#### SPI::BaseController

**File**: `app/controllers/spi/base_controller.rb`

**Features**:
- Skips CSRF verification for JSON requests
- TODO: Add authentication for production
- Base class for all SPI controllers

#### SPI::LLMResponsesController

**File**: `app/controllers/spi/llm_responses_controller.rb`

**Actions**:

1. **email_translation**: Receives translated content from LLM proxy
   - Parses JSON response
   - Updates EmailTemplate with subject, body_mjml, body_text
   - Error handling for not found, invalid JSON, etc.

2. **rate_limited**: Handles rate limit errors from Gemini
   - Logs error and retry_after time
   - TODO: Implement retry logic

3. **errored**: Handles general errors from LLM proxy
   - Logs error type and original params
   - TODO: Store errors in database, notify admins

**Routes**:
```ruby
namespace :spi do
  namespace :llm do
    post 'email_translation', to: 'llm_responses#email_translation'
    post 'rate_limited', to: 'llm_responses#rate_limited'
    post 'errored', to: 'llm_responses#errored'
  end
end
```

## Configuration

### Config Gem Settings

**File**: `../config/settings/local.yml`

```yaml
# SPI base URL for callbacks from LLM proxy
spi_base_url: http://localhost:3000/spi/

# LLM Proxy URL
llm_proxy_url: http://localhost:3064/exec
```

### Environment Variables

**Rails API**: None required (uses Jiki.config)

**LLM Proxy**:
- `GOOGLE_API_KEY` (required) - Gemini API key
- `REDIS_URL` (optional) - Redis for streaming (default: redis://127.0.0.1:6379/1)
- `PORT` (optional) - Server port (default: 3064)

## Development Workflow

### Starting Services

```bash
# Terminal 1: Redis (for future streaming)
redis-server

# Terminal 2: LLM Proxy
cd ../llm-proxy
./bin/dev

# Terminal 3: Rails API
cd ../api
bin/rails server
```

### Testing Translation

```ruby
# In Rails console
template = EmailTemplate.find_for(:level_completion, "basics-1", "en")

# Translate to single locale
EmailTemplate::TranslateToLocale.(template, "hu")

# Check placeholder was created
EmailTemplate.find_for(:level_completion, "basics-1", "hu")

# Wait a few seconds for LLM response
# Check again - should have translated content
EmailTemplate.find_for(:level_completion, "basics-1", "hu")

# Translate to all locales
EmailTemplate::TranslateToAllLocales.(template)
```

### Monitoring

Check Rails logs for:
- LLM proxy requests
- SPI callback responses
- Translation errors

Check LLM proxy logs for:
- Gemini API calls
- Streaming responses
- Callback attempts

## Error Handling

### Rate Limiting

When Gemini returns 429:
1. LLM proxy calls `/spi/llm/rate_limited`
2. Rails logs error with retry_after time
3. TODO: Implement exponential backoff retry

### Safety Filters

When content is blocked by Gemini:
1. LLM proxy calls `/spi/llm/errored`
2. Rails logs error_type: invalid_request
3. TODO: Notify admins, store in database

### Connection Errors

If LLM proxy is unavailable:
1. `LLM::Exec` raises error immediately
2. Background job will retry via Sidekiq
3. Check LLM proxy is running

## Future Enhancements

- Real-time streaming via ActionCable + Redis
- Retry logic with exponential backoff
- Error tracking and admin notifications
- Support for other LLM providers (OpenAI, Claude)
- Translation glossary/terminology management
- Human review workflow
- Translation metrics and quality tracking
- Batch processing optimization
- Rate limit aware job scheduling

## Related Documentation

- `.context/commands.md` - Mandate command pattern
- `.context/jobs.md` - Background job processing with Sidekiq
- `.context/configuration.md` - Jiki.config pattern
- `../llm-proxy/README.md` - LLM proxy service documentation

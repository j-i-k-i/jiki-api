# Email Template Translation System - Implementation Plan

## Overview

Implement an AI-powered translation system for email templates that:
- Creates new `EmailTemplate` records for each locale (no complex state tracking)
- Uses LLM (Gemini) to translate subject, body_mjml, and body_text in a single API call
- Follows async callback pattern via LLM proxy service
- Fire-and-forget approach (overwrites duplicates if they occur)

## Architecture

```
EmailTemplate::TranslateToLocale (Rails)
  → LLM::Exec (Rails)
    → HTTP POST to LLM Proxy (Node.js)
      → Gemini API
      → Callback to SPI::LLMResponsesController#email_translation (Rails)
        → Updates EmailTemplate record
```

## Part 1: LLM Proxy Service

**Location**: `/Users/iHiD/Code/jiki/llm-proxy` (parallel to api/admin/front-end)

### Files to Create

1. **`package.json`**
   - [ ] Dependencies: `@google/genai`, `express`, `ioredis`, `node-fetch`
   - [ ] Dev dependencies: `husky`, `lint-staged`, `prettier`
   - [ ] Type: `"module"`

2. **`lib/config.js`**
   - [ ] Export `REDIS_URL` (default: `redis://127.0.0.1:6379/1`)
   - [ ] Export `RAILS_SPI_BASE_URL` - load from `../config/settings/local.yml` → `spi_base_url`

3. **`lib/gemini.js`**
   - [ ] Import Google GenAI SDK
   - [ ] Export `handleGeminiPrompt(model, spiEndpoint, streamChannel, prompt)` function
   - [ ] Makes streaming request to Gemini API
   - [ ] Publishes chunks to Redis stream (for future real-time updates)
   - [ ] On completion, POSTs full response to `${RAILS_SPI_BASE_URL}${spiEndpoint}`
   - [ ] Error handling for rate limits (429), safety triggers, invalid requests

4. **`lib/server.js`**
   - [ ] Express server on port 8080
   - [ ] POST `/exec` endpoint
   - [ ] Accepts: `{service, model, spi_endpoint, stream_channel, prompt}`
   - [ ] Returns 202 immediately
   - [ ] Calls `handleGeminiPrompt()` async
   - [ ] Error handling: calls `/llm/rate_limited` or `/llm/errored` on failures
   - [ ] Custom exceptions: `RateLimitException`, `InvalidRequestException`

5. **`bin/dev`**
   - [ ] Bash script to install deps and start server
   - [ ] `yarn install --frozen-lockfile`
   - [ ] `node lib/server.js`

6. **`README.md`**
   - [ ] Setup and usage instructions
   - [ ] Environment variables needed
   - [ ] Example curl command

### Key Changes from Exercism Version
- Load `RAILS_SPI_BASE_URL` from `../config/settings/local.yml` → `spi_base_url`
- Same port (8080), same API structure
- Can reuse exact same code structure

## Part 2: Jiki Config Updates

**File**: `/Users/iHiD/Code/jiki/config/settings/local.yml`

- [ ] Add `spi_base_url: http://localhost:3000/spi/`

**Note**: This will be available to LLM proxy via `../config/settings/local.yml` and to Rails API via `Jiki::Config.spi_base_url`

## Part 3: Rails API Changes

### 1. Create `LLM::Exec` Command

**File**: `app/commands/llm/exec.rb`

- [ ] Include Mandate
- [ ] Initialize with: `service, model, prompt, spi_endpoint, stream_channel: nil`
- [ ] Validate all required params are present
- [ ] POST to proxy URL (`Jiki.config.llm_proxy_url`)
- [ ] Send payload: `{service, model, spi_endpoint: "llm/#{spi_endpoint}", stream_channel, prompt}`
- [ ] Use RestClient for HTTP POST

### 2. Create SPI Controller

**File**: `app/controllers/spi/base_controller.rb`

- [ ] Inherit from `ActionController::API`
- [ ] Skip CSRF verification for JSON requests
- [ ] TODO comment about authentication for production

**File**: `app/controllers/spi/llm_responses_controller.rb`

- [ ] Inherit from `SPI::BaseController`
- [ ] Action: `email_translation`
  - [ ] Find EmailTemplate by `params[:email_template_id]`
  - [ ] Parse `params[:resp]` as JSON (symbolize keys)
  - [ ] Update template with `subject`, `body_mjml`, `body_text` from response
  - [ ] Return 200 OK
- [ ] Action: `rate_limited` (placeholder for future retry logic)
- [ ] Action: `errored` (placeholder for future error logging)

**Routes**: `config/routes.rb`

- [ ] Add namespace `spi` with nested namespace `llm`
- [ ] Route `post 'email_translation'` to `llm_responses#email_translation`
- [ ] Route `post 'rate_limited'` to `llm_responses#rate_limited`
- [ ] Route `post 'errored'` to `llm_responses#errored`

### 3. Create `EmailTemplate::TranslateToLocale` Command

**File**: `app/commands/email_template/translate_to_locale.rb`

- [ ] Include Mandate
- [ ] Initialize with: `source_template, target_locale`
- [ ] Validation:
  - [ ] Raise error if `source_template.locale != "en"`
  - [ ] Raise error if `target_locale == "en"`
  - [ ] Raise error if target_locale not in configured locales
- [ ] Delete existing template if present (upsert pattern)
- [ ] Create placeholder EmailTemplate record with:
  - [ ] Same type and slug as source
  - [ ] Target locale
  - [ ] Empty subject, body_mjml, body_text
- [ ] Build translation prompt with context
- [ ] Call `LLM::Exec.(:gemini, :flash, prompt, spi_endpoint)`
- [ ] Return new template

**Prompt Requirements**:
- [ ] Clear instructions for localization expert
- [ ] Rules: maintain meaning/tone, preserve length, don't translate MJML tags/attributes
- [ ] Context: template type, slug, target locale name
- [ ] Show all three fields to translate (subject, body_mjml, body_text)
- [ ] Request JSON response with three fields

### 4. Create `EmailTemplate::TranslateToAllLocales` Command

**File**: `app/commands/email_template/translate_to_all_locales.rb`

- [ ] Include Mandate
- [ ] Initialize with: `source_template`
- [ ] Validation:
  - [ ] Raise error if `source_template.locale != "en"`
- [ ] Get target locales: `(I18n::SUPPORTED_LOCALES + I18n::WIP_LOCALES) - ["en"]`
- [ ] For each locale, call `EmailTemplate::TranslateToLocale.defer(source_template, locale)`

### 5. Configuration Updates

**File**: `config/locales/en.yml`

- [ ] Add locale display names under `locales:` key:
  - `en: "English"`
  - `hu: "Hungarian"`
  - `fr: "French"`

**Config Gem Settings**:
- [ ] Add `llm_proxy_url` to `../config/settings/local.yml` - defaults to `http://localhost:8080/exec`
- [ ] Access via `Jiki.config.llm_proxy_url` in Rails code
- [ ] Document `GOOGLE_API_KEY` - Gemini API key (environment variable used by LLM proxy Node.js process)
- [ ] Document `REDIS_URL` - Redis connection for streaming (environment variable used by LLM proxy Node.js process)

### 6. Dependencies

**Gemfile**:
- [ ] Add `gem 'httparty'`
- [ ] Run `bundle install`

## Testing

### Manual Testing Flow

1. [ ] Start Redis: `redis-server`
2. [ ] Start LLM Proxy: `cd ../llm-proxy && ./bin/dev`
3. [ ] Start Rails: `bin/rails server`
4. [ ] Create English template via admin UI or console
5. [ ] In Rails console:
   ```ruby
   template = EmailTemplate.find_for(:level_completion, "basics-1", "en")
   EmailTemplate::TranslateToLocale.(template, "hu")

   # Check that placeholder was created
   EmailTemplate.find_for(:level_completion, "basics-1", "hu")

   # Wait a few seconds for LLM response
   # Check again - should have translated content
   EmailTemplate.find_for(:level_completion, "basics-1", "hu")
   ```

### What to Test

- [ ] Source template validation (must be "en")
- [ ] Target locale validation (must be configured, cannot be "en")
- [ ] Placeholder template creation
- [ ] LLM callback updates template correctly
- [ ] MJML tags are not translated (only content)
- [ ] Variable placeholders preserved (e.g., `%{name}`)
- [ ] TranslateToAllLocales creates jobs for all locales
- [ ] Duplicate translations overwrite existing

## Implementation Order

1. [ ] Add `spi_base_url: http://localhost:3000/spi/` to `../config/settings/local.yml`
2. [ ] Create `/Users/iHiD/Code/jiki/llm-proxy` directory structure
3. [ ] Copy and adapt files from `exercism/llm-proxy`
4. [ ] Update LLM proxy config to load `spi_base_url` from `../config/settings/local.yml`
5. [ ] Test LLM proxy standalone with curl
6. [ ] Add `httparty` gem to Rails Gemfile
7. [ ] Create `LLM::Exec` command
8. [ ] Create SPI controller and routes
9. [ ] Create `EmailTemplate::TranslateToLocale` command with prompt building
10. [ ] Create `EmailTemplate::TranslateToAllLocales` command
11. [ ] Add locale names to i18n YAML
12. [ ] Manual testing (full flow)
13. [ ] Update `.context/` files with new translation patterns

## Before Committing

- [ ] Run `bin/rails test` - all tests must pass
- [ ] Run `bin/rubocop` - no linting errors
- [ ] Run `bin/brakeman` - no security issues
- [ ] Update `.context/commands.md` with LLM proxy startup
- [ ] Update `.context/architecture.md` with LLM integration pattern

## Future Enhancements

- Add authentication for SPI endpoints in production
- Implement retry logic in rate_limited/errored handlers
- Add ActionCable for real-time translation status updates in admin UI
- Track translation status/history
- Support for retranslating existing templates
- Glossary/terminology management for consistent translations
- Human review workflow
- Support for other content types (exercise instructions, etc.)

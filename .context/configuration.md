# Configuration

## Environment Configuration

### Database Configuration
- Config file: `config/database.yml`
- Development: Local PostgreSQL, database `jiki_development`
- Test: Local PostgreSQL, database `jiki_test`
- Production: Uses `DATABASE_URL` or configured with:
  - Database: `jiki_production`
  - Username: `jiki`
  - Password: `ENV["JIKI_DATABASE_PASSWORD"]`

### Rails Master Key
- Location: `config/master.key`
- Used for credentials encryption
- Required for production deployment
- Never commit to version control

### Environment Variables
```bash
# Database
DATABASE_URL              # Full database connection URL
JIKI_DATABASE_PASSWORD    # Production database password
RAILS_MAX_THREADS         # Connection pool size (default: 5)

# Rails
RAILS_ENV                 # Environment (development/test/production)
RAILS_MASTER_KEY          # Decryption key for credentials
RAILS_LOG_TO_STDOUT       # Enable stdout logging in production

# External Services (planned)
STRIPE_SECRET_KEY         # Stripe API key
STRIPE_WEBHOOK_SECRET     # Stripe webhook verification
VPN_API_KEY              # VPN detection service key
```

## CORS Configuration

### Setup Location
- File: `config/initializers/cors.rb`
- Currently commented out (needs activation)

### Example Configuration
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:3060', 'localhost:3071', 'jiki.io'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

## Storage Configuration

### Active Storage Setup
- Config file: `config/storage.yml`
- Development: Local disk storage
- Test: Temporary test storage
- Production: AWS S3 (to be configured)

### S3 Configuration (Production)
```yaml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: jiki-storage
```

## Action Cable Configuration

### Setup Location
- File: `config/cable.yml`
- Development: Async adapter (in-memory)
- Test: Test adapter
- Production: Redis adapter

### Redis Configuration (Production)
```yaml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: jiki_production
```

## Application Settings

### Time Zone
- Default: UTC
- Configure in `config/application.rb`:
```ruby
config.time_zone = 'UTC'
```

### Autoloading
- Zeitwerk autoloader (Rails default)
- Eager loading in production
- Lazy loading in development

### Middleware
- API-only middleware stack
- No session/cookie middleware by default
- Can add back if needed for specific features

## Docker Configuration

### Dockerfile Settings
- Ruby version: Matches `.ruby-version`
- Base image: Ruby slim for smaller size
- Multi-stage build for optimization
- Non-root user for security

### Container Environment
- Port: 80 (exposed)
- Workdir: `/rails`
- Entrypoint: `bin/docker-entrypoint`
- Default command: Thruster + Rails server

## CI/CD Configuration

### GitHub Actions
- File: `.github/workflows/ci.yml`
- Runs on push and pull requests
- Test matrix for multiple Ruby versions
- Database setup for tests

### Dependabot
- File: `.github/dependabot.yml`
- Automated dependency updates
- Security vulnerability alerts

## Development Tools Configuration

### RuboCop
- File: `.rubocop.yml`
- Rails Omakase style guide
- Run with `bin/rubocop`

### Brakeman
- Security scanner for Rails
- Run with `bin/brakeman`
- Configuration can be added to `.brakeman.yml`

## Testing Configuration

### Test Helper
- File: `test/test_helper.rb`
- Parallel test execution enabled
- Fixtures autoloaded
- Test environment setup

### Parallel Testing
- Workers: Number of processors
- Configured in test helper
- Speed up test suite execution

## Production Deployment Configuration

### Puma Web Server
- Config file: `config/puma.rb`
- Worker processes
- Thread pool configuration
- Preload app for performance

### Thruster
- HTTP/2 support
- Asset caching
- Compression
- X-Sendfile acceleration

## Logging Configuration

### Development
- Log to `log/development.log`
- Debug level logging
- SQL query logging enabled

### Production
- Log to stdout (for container environments)
- Info level logging
- Structured logging recommended

## Security Configuration

### Parameter Filtering
- File: `config/initializers/filter_parameter_logging.rb`
- Filters sensitive parameters from logs
- Default: `:password`
- Add more as needed

### Content Security Policy
- Removed in API-only mode
- Can be re-added if serving any HTML

### HTTPS/SSL
- Enforced in production
- Handled by load balancer/CDN
- Force SSL in Rails: `config.force_ssl = true`
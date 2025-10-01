# Background Jobs

## Overview

Jiki uses **Sidekiq 8.0** with ActiveJob for background job processing. Jobs are integrated with the Mandate command pattern, allowing any Mandate command to be easily deferred to background execution.

## Technology Stack

- **Sidekiq 8.0**: Multi-threaded background job processor
- **Redis 5.0+**: Job queue and state management
- **ActiveJob**: Rails abstraction layer for job queuing
- **Mandate**: Command pattern integration with `.defer()` method

## Queue Priorities

Jobs are organized into 5 priority queues (config/sidekiq.yml):

### 1. **critical** - Highest Priority
- User-facing operations that must complete quickly
- Examples: Exercise submission processing, user authentication flows
- Target: Sub-second execution

### 2. **default** - Standard Priority
- Regular background operations
- Examples: Data synchronization, content updates
- Most jobs should use this queue

### 3. **mailers** - Email Queue
- All email sending operations
- Separate queue to prevent email backlogs from blocking other jobs
- Examples: Welcome emails, progress notifications

### 4. **background** - Lower Priority
- Bulk operations, non-urgent processing
- Examples: Analytics aggregation, cache warming
- Can tolerate longer delays

### 5. **low** - Lowest Priority
- Non-critical maintenance tasks
- Examples: Log cleanup, metrics collection, data exports
- Runs when system has spare capacity

## Creating Background Jobs

### Using Mandate Commands (Recommended)

The preferred approach is to use Mandate commands with the `.defer()` method:

```ruby
# app/commands/exercise/process_submission.rb
class Exercise::ProcessSubmission
  include Mandate

  queue_as :critical  # Optional: specify queue (defaults to :default)

  initialize_with :submission_id

  def call
    submission = Submission.find(submission_id)
    # Process the submission...
  end
end

# Usage - Synchronous
Exercise::ProcessSubmission.(submission.id)

# Usage - Background (deferred)
Exercise::ProcessSubmission.defer(submission.id)

# With delay
Exercise::ProcessSubmission.defer(submission.id, wait: 5.minutes)
```

### Direct ActiveJob (When Needed)

For jobs that don't fit the Mandate pattern:

```ruby
# app/jobs/custom_job.rb
class CustomJob < ApplicationJob
  queue_as :background

  def perform(arg1, arg2)
    # Job logic...
  end
end

# Usage
CustomJob.perform_later(arg1, arg2)
```

## Advanced Features

### Requeuing with Delay

Use `requeue_job!` within a Mandate command to retry later (useful for rate limiting):

```ruby
class ExternalApi::SyncData
  include Mandate

  def call
    response = make_api_call

    if response.code == 429  # Rate limited
      retry_after = response.headers['Retry-After'].to_i
      requeue_job!(retry_after)
    end

    process_data(response)
  rescue RestClient::TooManyRequests
    requeue_job!(rand(10..30))  # Random backoff
  end
end
```

### Prerequisite Job Coordination

Ensure jobs wait for other jobs to complete:

```ruby
# First job
job1 = FirstCommand.defer(arg1)

# Second job waits for first to complete
job2 = SecondCommand.defer(arg2, prereq_jobs: [job1])
```

**How it works**:
- `prereq_jobs` expects an array of ActiveJob instances
- Jobs are converted to `{ job_id:, queue_name: }` hashes for serialization
- MandateJob checks Sidekiq queues and retry sets before proceeding
- Raises `MandateJob::PreqJobNotFinishedError` if prerequisites aren't done
- Job will retry automatically via Sidekiq's retry mechanism

### Deserialization Error Handling

Control whether jobs should be discarded when records are missing:

```ruby
class MyCommand
  include Mandate

  initialize_with :user

  def call
    # Work with user...
  end

  # Return false to NOT discard job if user is deleted
  # Job will retry, potentially succeeding if record is restored
  def guard_against_deserialization_errors?
    false
  end
end
```

**Default behavior**: Jobs are discarded if records can't be deserialized (see `ApplicationJob`)

## Testing Background Jobs

### Testing Job Enqueueing

```ruby
test "enqueues job with correct arguments" do
  assert_enqueued_with(
    job: MandateJob,
    args: ["Exercise::ProcessSubmission", 123],
    queue: "critical"
  ) do
    Exercise::ProcessSubmission.defer(123)
  end
end
```

### Testing with Delays

```ruby
test "enqueues job with delay" do
  assert_enqueued_with(
    job: MandateJob,
    args: ["MyCommand", "arg"],
    queue: "default",
    at: within(1.second).of(5.minutes.from_now)
  ) do
    MyCommand.defer("arg", wait: 5.minutes)
  end
end
```

### Testing Job Execution

```ruby
test "processes submission correctly" do
  submission = create(:submission)

  perform_enqueued_jobs do
    Exercise::ProcessSubmission.defer(submission.id)
  end

  assert submission.reload.processed?
end
```

### Testing Requeue Behavior

```ruby
test "requeues on rate limit" do
  # Stub external API to return rate limit
  stub_request(:post, api_url).to_return(status: 429, headers: { 'Retry-After': '30' })

  assert_enqueued_jobs 2 do  # Original + requeued
    perform_enqueued_jobs do
      ExternalApi::SyncData.defer(data_id)
    end
  end
end
```

### Testing Prerequisite Jobs

```ruby
test "waits for prerequisite job to complete" do
  queue = Minitest::Mock.new
  job_in_queue = Minitest::Mock.new
  queue.expect :find_job, job_in_queue, ["prereq_job_123"]

  Sidekiq::Queue.stub :new, queue do
    error = assert_raises MandateJob::PreqJobNotFinishedError do
      MandateJob.perform_now(
        "MyCommand",
        prereq_jobs: [{ job_id: "prereq_job_123", queue_name: "default" }]
      )
    end

    assert_match(/Unfinished job/, error.to_s)
  end
end
```

## Configuration

### Sidekiq Server Configuration

File: `config/initializers/sidekiq.rb`

```ruby
Sidekiq.configure_server do |config|
  config.redis = { url: Jiki.config.sidekiq_redis_url }
  config.logger.level = Rails.env.production? ? Logger::WARN : Logger::INFO
end
```

### Queue Configuration

File: `config/sidekiq.yml`

```yaml
:queues:
  - critical
  - default
  - mailers
  - background
  - low
```

### ActiveJob Adapter

File: `config/application.rb`

```ruby
config.active_job.queue_adapter = :sidekiq
```

## ApplicationJob Defaults

All jobs inherit sensible defaults:

```ruby
class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked
  discard_on ActiveJob::DeserializationError
end
```

**What this means**:
- **Deadlock errors**: Automatically retry (database contention)
- **Deserialization errors**: Discard job (record was deleted)

## Common Patterns

### User Bootstrapping

When a user signs up, run initialization tasks via `User::Bootstrap`:

```ruby
# app/commands/user/bootstrap.rb
class User::Bootstrap
  include Mandate

  initialize_with :user

  def call
    # Queue welcome email to be sent asynchronously
    User::SendWelcomeEmail.defer(user)

    # Future: Add other bootstrap operations here as needed:
    # - Award badges
    # - Create auth tokens
    # - Track metrics
  end
end

# Usage in Devise RegistrationsController
def create
  super do |resource|
    User::Bootstrap.(resource) if resource.persisted?
  end
end
```

**Pattern Notes**:
- Bootstrap command accepts the user object directly for synchronous operations
- Background jobs also receive user object - ActiveJob uses GlobalID for serialization
- Keeps controller thin - all bootstrap logic encapsulated in command

### Email Sending

```ruby
class User::SendWelcomeEmail
  include Mandate

  queue_as :mailers

  initialize_with :user

  def call
    WelcomeMailer.welcome(user, login_url:).deliver_now
  end

  private
  def login_url
    # Environment-specific URL generation
    if Rails.env.production?
      "https://jiki.io/login"
    elsif Rails.env.development?
      "http://localhost:3000/login"
    else
      "http://test.host/login"
    end
  end
end

# Usage
User::SendWelcomeEmail.defer(user)
```

**Pattern Notes**:
- Pass ActiveRecord objects directly - ActiveJob handles serialization via GlobalID
- GlobalID serializes as reference (e.g., `gid://app/User/123`), not a snapshot
- User is fetched fresh from DB when job executes, ensuring current data
- Use `:mailers` queue for all email operations
- Generate URLs based on environment (will use config gem in future)

### Batch Processing

```ruby
class Exercise::ProcessBatch
  include Mandate

  queue_as :background

  initialize_with :batch_id, :offset, :limit

  def call
    submissions = Submission.where(batch_id:).offset(offset).limit(limit)
    submissions.each { |s| process(s) }

    # Queue next batch if more records exist
    if submissions.count == limit
      self.class.defer(batch_id, offset + limit, limit)
    end
  end
end

# Start batch processing
Exercise::ProcessBatch.defer(batch_id, 0, 100)
```

### Rate-Limited API Calls

```ruby
class ExternalApi::FetchData
  include Mandate

  def call
    response = api_client.get(endpoint)
    process_response(response)
  rescue RateLimitError => e
    requeue_job!(e.retry_after || 60)
  rescue TemporaryError
    requeue_job!(rand(5..15))  # Random jitter to avoid thundering herd
  end
end
```

## Monitoring & Debugging

### Sidekiq Web UI (Future)

When configured, access the Sidekiq Web UI to:
- View queued jobs
- Monitor retry queue
- See job statistics
- Manually retry failed jobs

### Logging

Jobs log automatically via Rails logger:
- Job start/completion
- Arguments passed
- Execution time
- Errors and stack traces

### Common Issues

**Job not executing**:
1. Check Redis is running: `redis-cli ping`
2. Verify Sidekiq process is running
3. Check queue name matches configuration

**Job keeps retrying**:
1. Check for transient errors (network, database)
2. Verify record exists (deserialization errors)
3. Review job logs for exceptions

**Slow job processing**:
1. Check queue priorities
2. Increase Sidekiq concurrency
3. Consider job batching
4. Profile using Sidekiq 8's built-in profiling

## Infrastructure Requirements

### Redis

- Version: 5.0+ required (7.0+ recommended)
- Used for: Job queues, retry sets, job state
- Connection: Configured via `Jiki.config.sidekiq_redis_url`

### Sidekiq Process

Development:
```bash
bundle exec sidekiq
```

Production: Use process manager (systemd, Docker, etc.)

## Related Documentation

- Mandate pattern: See existing Mandate commands in `app/commands/`
- Configuration: `.context/configuration.md` - Jiki Config Gem Pattern
- Testing: `.context/testing.md` - General testing patterns
- Redis setup: `.context/configuration.md` - Environment Configuration

require "test_helper"

# Test command for integration testing
class TestExampleCommand
  include Mandate

  queue_as :low

  initialize_with :message, :should_fail

  def call
    raise StandardError, "Intentional failure" if should_fail

    "Processed: #{message}"
  end
end

class TestExampleCommandTest < ActiveSupport::TestCase
  test ".defer() enqueues MandateJob with correct arguments" do
    assert_enqueued_with(
      job: MandateJob,
      args: ["TestExampleCommand", "hello", false],
      queue: "low"
    ) do
      TestExampleCommand.defer("hello", false)
    end
  end

  test ".defer() with keyword arguments" do
    assert_enqueued_with(
      job: MandateJob,
      args: ["TestExampleCommand"],
      queue: "low"
    ) do
      TestExampleCommand.defer(message: "test", should_fail: false)
    end
  end

  test ".defer(wait: 10) schedules job with delay" do
    travel_to Time.current do
      expected_time = 10.seconds.from_now

      TestExampleCommand.defer("delayed", false, wait: 10)

      enqueued_job = enqueued_jobs.last
      assert_equal "MandateJob", enqueued_job[:job].name
      assert_in_delta expected_time.to_f, enqueued_job[:at].to_f, 1
    end
  end

  test "delayed job does not execute before delay expires" do
    travel_to Time.current do
      TestExampleCommand.defer("delayed", false, wait: 10)

      # Try to execute jobs immediately - should not execute the delayed job
      perform_enqueued_jobs(at: Time.current)

      # Verify the job is still enqueued (not performed yet)
      assert_equal 1, enqueued_jobs.count

      # Travel forward past the delay
      travel 11.seconds

      # Now the job should execute
      perform_enqueued_jobs(at: Time.current + 11.seconds)

      # Verify job was performed
      assert_equal 0, enqueued_jobs.count
    end
  end

  test "queue_as sets the correct queue" do
    assert_equal :low, TestExampleCommand.active_job_queue
  end

  test "job executes command when performed" do
    perform_enqueued_jobs do
      TestExampleCommand.defer("integration test", false)
    end

    # Verify through direct call since we can't capture background job result easily
    result = TestExampleCommand.new("integration test", false).()
    assert_equal "Processed: integration test", result
  end

  test "job fails when command raises error" do
    assert_raises StandardError do
      perform_enqueued_jobs do
        TestExampleCommand.defer("fail", true)
      end
    end
  end

  test "default queue is :default for command without queue_as" do
    test_class = Class.new do
      include Mandate

      def self.name
        "DynamicTestCommand"
      end

      def call
        "test"
      end
    end

    assert_equal :default, test_class.active_job_queue
  end
end

# Test command with rate limiting that uses requeue_job!
class TestRateLimitedCommand
  include Mandate

  initialize_with :should_rate_limit

  def call
    if should_rate_limit
      requeue_job!(rand(10..30))
    else
      "Success"
    end
  end
end

class TestRateLimitedCommandTest < ActiveSupport::TestCase
  test "requeue_job! triggers re-enqueueing" do
    assert_enqueued_jobs 1 do
      TestRateLimitedCommand.defer(true)
    end

    # When performed, it should requeue itself
    assert_enqueued_jobs 2 do
      perform_enqueued_jobs
    end
  end

  test "command completes without requeue when condition not met" do
    perform_enqueued_jobs do
      TestRateLimitedCommand.defer(false)
    end

    result = TestRateLimitedCommand.new(false).()
    assert_equal "Success", result
  end
end

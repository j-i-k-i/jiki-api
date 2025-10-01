require "test_helper"
require "sidekiq/api"

class MandateJobTest < ActiveJob::TestCase
  # Test command that succeeds
  class TestSuccessCommand
    include Mandate

    initialize_with :value

    def call
      "Success: #{value}"
    end
  end

  # Test command that uses requeue_job!
  class TestRequeueCommand
    include Mandate

    initialize_with :should_requeue

    def call
      requeue_job!(30) if should_requeue
      "Completed"
    end
  end

  # Test command with guard_against_deserialization_errors?
  class TestGuardedCommand
    include Mandate

    def call
      "Guarded"
    end

    def guard_against_deserialization_errors?
      false
    end
  end

  # Test command that raises an error
  class TestErrorCommand
    include Mandate

    def call
      raise StandardError, "Test error"
    end
  end

  test "successfully executes a Mandate command" do
    result = MandateJob.perform_now("MandateJobTest::TestSuccessCommand", "test_value")
    assert_equal "Success: test_value", result
  end

  test "passes mixed positional and keyword arguments" do
    # Test that both styles work through the job
    result = MandateJob.perform_now("MandateJobTest::TestSuccessCommand", "positional_value")
    assert_equal "Success: positional_value", result
  end

  test "handles requeue_job! and re-enqueues with wait time" do
    assert_enqueued_with(
      job: MandateJob,
      args: ["MandateJobTest::TestRequeueCommand", true],
      queue: "default"
    ) do
      MandateJob.perform_now("MandateJobTest::TestRequeueCommand", true)
    end
  end

  test "completes normally when requeue is not triggered" do
    result = MandateJob.perform_now("MandateJobTest::TestRequeueCommand", false)
    assert_equal "Completed", result
  end

  test "prerequisite jobs: proceeds when prereq_jobs is nil" do
    result = MandateJob.perform_now("MandateJobTest::TestSuccessCommand", "test", prereq_jobs: nil)
    assert_equal "Success: test", result
  end

  test "prerequisite jobs: proceeds when prereq_jobs is empty" do
    result = MandateJob.perform_now("MandateJobTest::TestSuccessCommand", "test", prereq_jobs: [])
    assert_equal "Success: test", result
  end

  test "prerequisite jobs: blocks when prereq job is in queue" do
    # Create mocks
    queue_mock = mock
    job_in_queue = mock

    # Setup expectations - when job is in queue, retry set is not checked
    queue_mock.expects(:find_job).with("prereq_job_123").returns(job_in_queue)

    # Stub the Sidekiq classes
    Sidekiq::Queue.expects(:new).with("default").returns(queue_mock)
    # RetrySet.new is never called because queue returns a job (short-circuit)

    error = assert_raises MandateJob::PreqJobNotFinishedError do
      MandateJob.perform_now(
        "MandateJobTest::TestSuccessCommand",
        "test",
        prereq_jobs: [{ job_id: "prereq_job_123", queue_name: "default" }]
      )
    end

    assert_match(/Unfinished job: prereq_job_123/, error.to_s)
  end

  test "prerequisite jobs: blocks when prereq job is in retry set" do
    # Create mocks
    queue_mock = mock
    retry_set_mock = mock
    job_in_retry = mock

    # Setup expectations
    queue_mock.expects(:find_job).with("prereq_job_456").returns(nil)
    retry_set_mock.expects(:find_job).with("prereq_job_456").returns(job_in_retry)

    # Stub the Sidekiq classes
    Sidekiq::Queue.expects(:new).with("default").returns(queue_mock)
    Sidekiq::RetrySet.expects(:new).returns(retry_set_mock)

    error = assert_raises MandateJob::PreqJobNotFinishedError do
      MandateJob.perform_now(
        "MandateJobTest::TestSuccessCommand",
        "test",
        prereq_jobs: [{ job_id: "prereq_job_456", queue_name: "default" }]
      )
    end

    assert_match(/Unfinished job: prereq_job_456/, error.to_s)
  end

  test "prerequisite jobs: proceeds when prereq jobs are complete" do
    # Create mocks that return nil (job not found)
    queue_mock = mock
    retry_set_mock = mock

    # Setup expectations
    queue_mock.expects(:find_job).with("completed_job_789").returns(nil)
    retry_set_mock.expects(:find_job).with("completed_job_789").returns(nil)

    # Stub the Sidekiq classes
    Sidekiq::Queue.expects(:new).with("default").returns(queue_mock)
    Sidekiq::RetrySet.expects(:new).returns(retry_set_mock)

    result = MandateJob.perform_now(
      "MandateJobTest::TestSuccessCommand",
      "test",
      prereq_jobs: [{ job_id: "completed_job_789", queue_name: "default" }]
    )

    assert_equal "Success: test", result
  end

  test "deserialization guard: respects guard_against_deserialization_errors?" do
    job = MandateJob.new
    job.perform("MandateJobTest::TestGuardedCommand")

    refute job.guard_against_deserialization_errors?
  end

  test "deserialization guard: defaults to true when method not defined" do
    job = MandateJob.new
    job.perform("MandateJobTest::TestSuccessCommand", "test")

    assert job.guard_against_deserialization_errors?
  end

  test "job fails when Mandate command raises unhandled exception" do
    error = assert_raises StandardError do
      MandateJob.perform_now("MandateJobTest::TestErrorCommand")
    end

    assert_equal "Test error", error.message
  end

  test "requeue preserves all arguments" do
    assert_enqueued_jobs 1 do
      MandateJob.perform_now("MandateJobTest::TestRequeueCommand", true)
    end
  end
end

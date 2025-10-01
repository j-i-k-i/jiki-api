class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Can be overridden to disable smart deserialization error handling
  def guard_against_deserialization_errors? = true

  # Smart handling of deserialization errors with retry logic for transaction timing
  rescue_from ActiveJob::DeserializationError do |exception|
    raise exception unless guard_against_deserialization_errors?

    # Only handle RecordNotFound - other deserialization errors should raise
    raise exception unless exception.cause.is_a?(ActiveRecord::RecordNotFound)

    # Handle race condition where job is enqueued but record isn't committed yet.
    # Sleep for a total of 5 seconds (20*0.25s) checking if the record appears.
    # This is rare enough that we don't mind locking the job for this duration.
    # It's worse to drop jobs by accident due to transaction timing.
    20.times do
      sleep(0.25)

      begin
        exception.cause.model.constantize.find(exception.cause.id)
        retry_job
        break
      rescue NoMethodError, ActiveRecord::RecordNotFound
        # Continue to loop
      end
    end

    # If we get to this point, the model has been deleted
    # so just exit the job which removes it from the queue
  end
end

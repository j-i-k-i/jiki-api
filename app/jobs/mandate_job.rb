class MandateJob < ApplicationJob
  class MandateJobNeedsRequeuing < RuntimeError
    attr_reader :wait

    def initialize(wait)
      @wait = wait
      super(nil)
    end
  end

  class PreqJobNotFinishedError < RuntimeError
    def initialize(job_id)
      @job_id = job_id
      super(nil)
    end

    def to_s
      "Unfinished job: #{job_id}"
    end

    private
    attr_reader :job_id
  end

  def perform(cmd, *args, **kwargs)
    # Extract and validate prerequisite jobs before deletion
    # We need to preserve this for requeuing in case of rate limiting
    prereq_jobs_value = kwargs.delete(:prereq_jobs)
    __guard_prereq_jobs__!(prereq_jobs_value)

    instance = cmd.constantize.new(*args, **kwargs)
    instance.define_singleton_method(:requeue_job!) { |wait| raise MandateJobNeedsRequeuing, wait }
    self.define_singleton_method :guard_against_deserialization_errors? do
      return true unless instance.respond_to?(:guard_against_deserialization_errors?)

      instance.guard_against_deserialization_errors?
    end

    instance.()
  rescue MandateJobNeedsRequeuing => e
    # Preserve prerequisite jobs when requeuing to maintain dependency chain
    requeue_kwargs = kwargs.merge(wait: e.wait)
    requeue_kwargs[:prereq_jobs] = prereq_jobs_value if prereq_jobs_value.present?

    cmd.constantize.defer(*args, **requeue_kwargs)
  end

  def __guard_prereq_jobs__!(prereq_jobs)
    return unless prereq_jobs.present?

    prereq_jobs.each do |job|
      jid = job[:job_id]

      # Check if prerequisite job is still pending in its queue or being retried.
      # We intentionally don't check DeadSet - if a prerequisite job dies, we allow
      # the dependent job to proceed. This matches Exercism's behavior and is an
      # acceptable trade-off, as most failed jobs should retry automatically.
      #
      # Note: Creates new Queue/RetrySet objects per iteration. This could be optimized
      # by caching, but impact is minimal as most jobs have 0-1 prerequisites.
      if Sidekiq::Queue.new(job[:queue_name]).find_job(jid) ||
         Sidekiq::RetrySet.new.find_job(jid)
        raise PreqJobNotFinishedError, jid
      end
    end
  end
end

require 'mandate'

# MandateJob must be defined within to_prepare to ensure ApplicationJob is autoloaded first.
# This is the standard Rails 8 pattern for initializers that depend on autoloaded constants.
# rubocop:disable Lint/ConstantDefinitionInBlock
Rails.application.config.to_prepare do
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

  # Extend Mandate gem with ActiveJob integration.
  # This reopens the Mandate module to add ActiveJobQueuer extension, following the same
  # pattern as Exercism. We replicate the original Mandate.included behavior (extending
  # Memoize, CallInjector, InitializerInjector) and add our ActiveJobQueuer on top.
  # This is intentional module reopening, not monkey-patching.
  module Mandate
    module ActiveJobQueuer
      def self.extended(base)
        class << base
          def queue_as(queue)
            @active_job_queue = queue
          end

          def active_job_queue
            @active_job_queue || :default
          end
        end
      end

      def defer(*args, wait: nil, **kwargs)
        # We need to convert the jobs to a hash before we serialize as there's no serialization
        # format for a job. We do this here to avoid cluttering the codebase with this logic.
        if (prereqs = kwargs.delete(:prereq_jobs))
          prereqs.map! do |job|
            # If already a hash (e.g., from requeuing), pass through
            # Otherwise convert from job object to hash
            if job.is_a?(Hash)
              job
            else
              {
                job_id: job.provider_job_id,
                queue_name: job.queue_name
              }
            end
          end
          kwargs[:prereq_jobs] = prereqs if prereqs.present?
        end

        MandateJob.set(
          queue: active_job_queue,
          wait:
        ).perform_later(self.name, *args, **kwargs)
      end
    end

    def self.included(base)
      # Upstream - replicate Mandate gem's original behavior
      base.extend(Memoize)
      base.extend(CallInjector)
      base.extend(InitializerInjector)

      # New - add background job integration
      base.extend(ActiveJobQueuer)
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock

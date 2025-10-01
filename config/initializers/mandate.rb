require 'mandate'

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

module VideoProduction
  class Node < ApplicationRecord
    disable_sti!

    self.table_name = 'video_production_nodes'

    belongs_to :pipeline, class_name: 'VideoProduction::Pipeline', inverse_of: :nodes

    validates :uuid, presence: true, uniqueness: true, on: :update
    validates :title, presence: true
    validates :type, presence: true, inclusion: {
      in: %w[asset generate-talking-head generate-animation generate-voiceover
             render-code mix-audio merge-videos compose-video]
    }
    validates :status, inclusion: { in: %w[pending in_progress completed failed] }

    # JSONB accessors
    store_accessor :config, :provider
    store_accessor :metadata, :started_at, :completed_at, :job_id, :cost, :retries, :error, :process_uuid
    store_accessor :output, :s3_key, :local_file, :duration, :size

    # Scopes
    scope :pending, -> { where(status: 'pending') }
    scope :in_progress, -> { where(status: 'in_progress') }
    scope :completed, -> { where(status: 'completed') }
    scope :failed, -> { where(status: 'failed') }

    before_validation(on: :create) do
      self.uuid ||= SecureRandom.uuid
    end

    def to_param = uuid

    # Check if all input nodes are completed
    def inputs_satisfied?
      return true if inputs.blank?

      input_node_ids = inputs.values.flatten.compact
      return true if input_node_ids.empty?

      input_nodes = self.class.where(pipeline_id: pipeline_id, uuid: input_node_ids)
      input_nodes.all? { |node| node.status == 'completed' }
    end

    # Check if ready to execute
    def ready_to_execute?
      status == 'pending' && is_valid? && inputs_satisfied?
    end
  end
end

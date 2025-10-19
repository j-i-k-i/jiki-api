class VideoProduction::Node::ExecutionFailed
  include Mandate

  initialize_with :node, :error_message, :process_uuid

  def call
    node.with_lock do
      # Verify this execution still owns the node (not a stale job)
      # If process_uuid is nil, execution never started, so we should always mark as failed
      return unless process_uuid.nil? || node.process_uuid == process_uuid

      node.update!(status: 'failed', metadata: new_metadata)
    end
  end

  private
  def new_metadata
    (node.metadata || {}).merge(
      error: error_message,
      completed_at: Time.current.iso8601
    )
  end
end

class VideoProduction::Node::Update
  include Mandate

  initialize_with :node, :attributes

  def call
    node.assign_attributes(attributes)
    validation_result = VideoProduction::Node::Validate.(node)
    node.assign_attributes(validation_result)

    # Raise exception if validation failed
    unless validation_result[:is_valid]
      error_messages = validation_result[:validation_errors].map { |key, msg| "Input '#{key}' #{msg}" }.join(', ')
      raise VideoProductionBadInputsError, error_messages
    end

    node[:status] = 'pending' if should_reset_status?

    node.save!
    node
  end

  private
  def should_reset_status?
    # Reset to pending if structure changed (not title)
    structure_keys = %w[inputs config asset]
    (node.changes.keys & structure_keys).present?
  end
end

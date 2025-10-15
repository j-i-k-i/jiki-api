class VideoProduction::Node::Update
  include Mandate

  initialize_with :node, :attributes

  def call
    validate_inputs!

    node.assign_attributes(attributes)
    node[:status] = 'pending' if should_reset_status?(attributes.keys)
    node.save!

    node
  end

  private
  def validate_inputs!
    return unless attributes.key?(:inputs)

    VideoProduction::Node::ValidateInputs.(
      node.type,
      attributes[:inputs],
      node.pipeline_id
    )
  end

  def should_reset_status?(_changed_keys)
    # Reset to pending if structure changed (not title)
    structure_keys = %w[inputs config asset]
    (node.changes.keys & structure_keys).present?
  end
end

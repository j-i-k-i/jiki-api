class VideoProduction::Node::Create
  include Mandate

  initialize_with :pipeline, :params

  def call
    node = pipeline.nodes.new(params)
    validation_result = VideoProduction::Node::Validate.(node)
    node.assign_attributes(validation_result)

    # Raise exception if validation failed
    unless validation_result[:is_valid]
      error_messages = validation_result[:validation_errors].map { |key, msg| "Input '#{key}' #{msg}" }.join(', ')
      raise VideoProductionBadInputsError, error_messages
    end

    node.save!
    node
  end
end

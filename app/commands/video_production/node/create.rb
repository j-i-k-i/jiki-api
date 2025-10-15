class VideoProduction::Node::Create
  include Mandate

  initialize_with :pipeline, :params

  def call
    validate_inputs!
    pipeline.nodes.create!(params)
  end

  private
  def validate_inputs!
    return unless params.key?(:inputs)
    return unless params[:inputs].present?

    VideoProduction::Node::ValidateInputs.(
      params[:type],
      params[:inputs],
      pipeline.id
    )
  end
end

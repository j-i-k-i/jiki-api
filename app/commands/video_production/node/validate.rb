class VideoProduction::Node::Validate
  include Mandate

  initialize_with :node

  def call
    # No schema available - node remains invalid
    unless schema
      return {
        is_valid: false,
        validation_errors: { invalid_type: "Unknown node type: #{node.type}" }
      }
    end

    # Check provider field exists
    if node.provider.blank?
      return {
        is_valid: false,
        validation_errors: { provider: "Provider is required" }
      }
    end

    # Get provider-specific config from schema
    provider_configs = begin
      schema.const_get(:PROVIDER_CONFIGS)
    rescue StandardError
      {}
    end
    unless provider_configs.key?(node.provider)
      return {
        is_valid: false,
        validation_errors: { provider: "Unknown provider '#{node.provider}' for #{node.type} nodes" }
      }
    end

    # Validate inputs and config with provider-specific schema
    input_errors = VideoProduction::Node::ValidateInputs.(node, schema::INPUTS)
    config_errors = VideoProduction::Node::ValidateConfig.(node, schema, node.provider)

    errors = input_errors.merge(config_errors)

    { is_valid: errors.empty?, validation_errors: errors }
  end

  private
  memoize
  def schema
    case node.type
    when 'asset'
      VideoProduction::Node::Schemas::Asset
    when 'generate-talking-head'
      VideoProduction::Node::Schemas::GenerateTalkingHead
    when 'generate-animation'
      VideoProduction::Node::Schemas::GenerateAnimation
    when 'generate-voiceover'
      VideoProduction::Node::Schemas::GenerateVoiceover
    when 'render-code'
      VideoProduction::Node::Schemas::RenderCode
    when 'mix-audio'
      VideoProduction::Node::Schemas::MixAudio
    when 'merge-videos'
      VideoProduction::Node::Schemas::MergeVideos
    when 'compose-video'
      VideoProduction::Node::Schemas::ComposeVideo
      # Unknown node type - node will remain is_valid: false
    end
  end
end

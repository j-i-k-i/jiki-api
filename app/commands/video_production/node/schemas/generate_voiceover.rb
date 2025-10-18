class VideoProduction::Node::Schemas::GenerateVoiceover
  INPUT_SCHEMA = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with voiceover script'
    }
  }.freeze

  CONFIG_SCHEMA = {}.freeze
end

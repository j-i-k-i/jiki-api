class VideoProduction::Node::Schemas::GenerateVoiceover
  INPUTS = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with voiceover script'
    }
  }.freeze

  CONFIG = {}.freeze
end

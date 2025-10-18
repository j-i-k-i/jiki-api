class VideoProduction::Node::Schemas::GenerateAnimation
  INPUT_SCHEMA = {
    'prompt' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with animation prompt'
    },
    'referenceImage' => {
      type: :single,
      required: false,
      description: 'Optional reference image for animation generation'
    }
  }.freeze

  CONFIG_SCHEMA = {}.freeze
end

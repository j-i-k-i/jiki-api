class VideoProduction::Node::Schemas::GenerateTalkingHead
  INPUTS = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with script text'
    }
  }.freeze

  CONFIG = {}.freeze
end

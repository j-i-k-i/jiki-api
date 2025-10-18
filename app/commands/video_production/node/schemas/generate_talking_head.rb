class VideoProduction::Node::Schemas::GenerateTalkingHead
  INPUT_SCHEMA = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with script text'
    }
  }.freeze

  CONFIG_SCHEMA = {}.freeze
end

class VideoProduction::Node::Schemas::RenderCode
  INPUT_SCHEMA = {
    'config' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with Remotion config JSON'
    }
  }.freeze

  CONFIG_SCHEMA = {}.freeze
end

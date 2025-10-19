class VideoProduction::Node::Schemas::RenderCode
  INPUTS = {
    'config' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with Remotion config JSON'
    }
  }.freeze

  CONFIG = {}.freeze
end

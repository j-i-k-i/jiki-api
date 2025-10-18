class VideoProduction::Node::Schemas::RenderCode
  INPUTS = {
    'config' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with Remotion config JSON'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'remotion' => {
      'composition' => {
        type: :string,
        required: true,
        description: 'Remotion composition name to render'
      },
      'fps' => {
        type: :integer,
        required: false,
        description: 'Frames per second (default: 30)'
      },
      'quality' => {
        type: :integer,
        required: false,
        description: 'Video quality 0-100 (default: 80)'
      }
    }
  }.freeze
end

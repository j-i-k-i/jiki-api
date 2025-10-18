class VideoProduction::Node::Schemas::ComposeVideo
  INPUTS = {
    'background' => {
      type: :single,
      required: true,
      description: 'Background video node reference'
    },
    'overlay' => {
      type: :single,
      required: true,
      description: 'Overlay video node reference (e.g., talking head)'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'ffmpeg' => {
      'position' => {
        type: :string,
        required: false,
        allowed_values: %w[top-left top-right bottom-left bottom-right center],
        description: 'Position of the overlay video'
      },
      'scale' => {
        type: :string,
        required: false,
        description: 'Scale factor for overlay (e.g., "0.3" for 30%)'
      }
    }
  }.freeze
end

class VideoProduction::Node::Schemas::GenerateAnimation
  INPUTS = {
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

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'veo3' => {
      'model' => {
        type: :string,
        required: false,
        allowed_values: %w[standard premium],
        description: 'Veo3 model tier'
      },
      'aspect_ratio' => {
        type: :string,
        required: false,
        allowed_values: %w[16:9 9:16 1:1],
        description: 'Video aspect ratio'
      }
    },
    'runway' => {
      'generation' => {
        type: :string,
        required: false,
        allowed_values: %w[gen2 gen3],
        description: 'Runway generation version'
      }
    },
    'stability' => {}
  }.freeze
end

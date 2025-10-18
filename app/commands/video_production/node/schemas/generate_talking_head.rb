class VideoProduction::Node::Schemas::GenerateTalkingHead
  INPUTS = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with script text'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'heygen' => {
      'avatar_id' => {
        type: :string,
        required: true,
        description: 'HeyGen avatar ID'
      },
      'voice_id' => {
        type: :string,
        required: true,
        description: 'HeyGen voice ID'
      }
    }
  }.freeze
end

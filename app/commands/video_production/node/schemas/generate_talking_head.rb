class VideoProduction::Node::Schemas::GenerateTalkingHead
  INPUTS = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with script text'
    }
  }.freeze

  CONFIG = {
    'avatar_id' => {
      type: :string,
      required: true,
      description: 'HeyGen avatar ID'
    },
    'voice_id' => {
      type: :string,
      required: true,
      description: 'HeyGen voice ID'
    },
    'provider' => {
      type: :string,
      required: true,
      allowed_values: %w[heygen],
      description: 'Talking head generation provider'
    }
  }.freeze
end

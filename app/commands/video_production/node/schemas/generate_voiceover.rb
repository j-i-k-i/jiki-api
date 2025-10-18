class VideoProduction::Node::Schemas::GenerateVoiceover
  INPUTS = {
    'script' => {
      type: :single,
      required: false,
      description: 'Reference to asset node with voiceover script'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'elevenlabs' => {
      'voice_id' => {
        type: :string,
        required: true,
        description: 'ElevenLabs voice ID'
      },
      'model' => {
        type: :string,
        required: false,
        allowed_values: %w[eleven_monolingual_v1 eleven_multilingual_v2],
        description: 'Voice model to use'
      }
    }
  }.freeze
end

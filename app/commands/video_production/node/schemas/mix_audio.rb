class VideoProduction::Node::Schemas::MixAudio
  INPUTS = {
    'video' => {
      type: :single,
      required: true,
      description: 'Reference to video node'
    },
    'audio' => {
      type: :single,
      required: true,
      description: 'Reference to audio node'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'ffmpeg' => {
      'audio_codec' => {
        type: :string,
        required: false,
        allowed_values: %w[aac mp3 opus],
        description: 'Audio codec to use'
      },
      'volume' => {
        type: :integer,
        required: false,
        description: 'Audio volume adjustment (0-200, default 100)'
      }
    }
  }.freeze
end

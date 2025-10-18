class VideoProduction::Node::Schemas::MergeVideos
  INPUTS = {
    'segments' => {
      type: :multiple,
      required: true,
      min_count: 2,
      max_count: nil,
      description: 'Array of video node references to concatenate'
    }
  }.freeze

  # Provider-specific config schemas
  PROVIDER_CONFIGS = {
    'ffmpeg' => {
      'output_format' => {
        type: :string,
        required: false,
        allowed_values: %w[mp4 webm],
        description: 'Output video format'
      },
      'preset' => {
        type: :string,
        required: false,
        allowed_values: %w[ultrafast superfast veryfast faster fast medium slow slower veryslow],
        description: 'FFmpeg encoding preset'
      }
    }
  }.freeze
end

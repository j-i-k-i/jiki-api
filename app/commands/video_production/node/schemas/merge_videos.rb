class VideoProduction::Node::Schemas::MergeVideos
  INPUT_SCHEMA = {
    'segments' => {
      type: :multiple,
      required: true,
      min_count: 2,
      max_count: nil,
      description: 'Array of video node references to concatenate'
    }
  }.freeze

  CONFIG_SCHEMA = {
    # For merge-videos, config is typically minimal (FFmpeg provider is default)
    # Add provider-specific validation here if needed in the future
  }.freeze
end

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

  CONFIG = {}.freeze
end

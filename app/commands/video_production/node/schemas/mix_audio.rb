class VideoProduction::Node::Schemas::MixAudio
  INPUT_SCHEMA = {
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

  CONFIG_SCHEMA = {}.freeze
end

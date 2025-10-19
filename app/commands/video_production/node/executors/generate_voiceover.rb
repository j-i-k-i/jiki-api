class VideoProduction::Node::Executors::GenerateVoiceover
  include Mandate

  queue_as :video_production

  initialize_with :node

  def call
    # 1. Mark execution as started and get process_uuid
    process_uuid = VideoProduction::Node::ExecutionStarted.(node, {})

    # 2. Route to the appropriate provider based on node provider
    case node.provider
    when 'elevenlabs'
      VideoProduction::APIs::ElevenLabs::GenerateAudio.(node, process_uuid)
    else
      raise "Unknown voiceover provider: #{node.provider.inspect}"
    end
  rescue StandardError => e
    VideoProduction::Node::ExecutionFailed.(node, e.message, process_uuid)
    raise
  end
end

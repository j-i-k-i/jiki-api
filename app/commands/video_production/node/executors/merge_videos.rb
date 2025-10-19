class VideoProduction::Node::Executors::MergeVideos
  include Mandate

  queue_as :video_production

  initialize_with :node

  def call
    # Initialize process_uuid to nil in case of early exception
    process_uuid = nil

    # 1. Mark node as started and get process_uuid
    process_uuid = VideoProduction::Node::ExecutionStarted.(node, {})

    # 2. Validate inputs
    segment_ids = node.inputs['segments'] || []
    raise "No segments specified" if segment_ids.empty?
    raise "At least 2 segments required" if segment_ids.length < 2

    # 3. Get input nodes and their S3 keys
    input_nodes = VideoProduction::Node.where(uuid: segment_ids).index_by(&:uuid)

    # Preserve order from inputs array
    ordered_inputs = segment_ids.map { |uuid| input_nodes[uuid] }

    # Validate all inputs have outputs
    ordered_inputs.each do |input_node|
      raise "Input node #{input_node&.id || 'unknown'} has no output" unless input_node&.output&.dig('s3_key')
    end

    # 4. Build S3 URLs for Lambda
    bucket = Jiki.config.s3_bucket_video_production
    input_urls = ordered_inputs.map do |input_node|
      "s3://#{bucket}/#{input_node.output['s3_key']}"
    end

    # 5. Invoke Lambda to merge videos
    output_key = "pipelines/#{node.pipeline.uuid}/nodes/#{node.uuid}/output.mp4"

    result = VideoProduction::InvokeLambda.(
      lambda_function_name,
      {
        input_videos: input_urls,
        output_bucket: bucket,
        output_key: output_key
      }
    )

    # 6. Update node with output
    output = {
      type: 'video',
      s3_key: result[:s3_key],
      duration: result[:duration],
      size: result[:size]
    }
    VideoProduction::Node::ExecutionSucceeded.(node, output, process_uuid)
  rescue StandardError => e
    VideoProduction::Node::ExecutionFailed.(node, e.message, process_uuid)
    raise
  end

  private
  def lambda_function_name
    # Get function name from environment or use default
    # In production this would be: jiki-video-merger-production
    env = ENV.fetch('RAILS_ENV', 'development')
    ENV.fetch('VIDEO_MERGER_LAMBDA_NAME', "jiki-video-merger-#{env}")
  end
end

class VideoProduction::APIs::ElevenLabs::ProcessResult
  include Mandate

  initialize_with :node_uuid, :process_uuid, :audio_url

  # ElevenLabs API endpoint
  BASE_URL = 'https://api.elevenlabs.io/v1'.freeze

  def call
    # 1. Download audio from ElevenLabs
    audio_data = download_from_elevenlabs!

    # 2. Upload to S3
    s3_key = upload_to_s3!(audio_data)

    # 3. Get metadata
    audio_size = audio_data.bytesize

    # 4. Build output hash
    output = {
      type: 'audio',
      s3_key: s3_key,
      size: audio_size
    }

    # 5. Update node with output
    VideoProduction::Node::ExecutionSucceeded.(node, output, process_uuid)
  end

  private
  memoize
  def node = VideoProduction::Node.find_by!(uuid: node_uuid)

  def download_from_elevenlabs!
    response = HTTParty.get(
      audio_url,
      headers: { 'xi-api-key' => Jiki.secrets.elevenlabs_api_key }
    )

    raise "Failed to download audio from ElevenLabs: #{response.code} - #{response.body}" unless response.code == 200

    response.body
  end

  def upload_to_s3!(audio_data)
    s3_key = "pipelines/#{node.pipeline.uuid}/nodes/#{node_uuid}/audio.mp3"
    s3_client = Aws::S3::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1'))

    s3_client.put_object(
      bucket: ENV.fetch('AWS_S3_BUCKET', 'test-bucket'),
      key: s3_key,
      body: audio_data,
      content_type: 'audio/mpeg'
    )

    s3_key
  end
end

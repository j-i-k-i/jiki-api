class VideoProduction::InvokeLambdaLocal
  include Mandate

  initialize_with :function_name, :payload

  def call
    # Execute Node.js with the handler
    stdout, stderr, = Open3.capture3(
      aws_env,
      'node',
      '-e', node_script,
      JSON.generate(payload),
      chdir: Rails.root
    )

    # Log stderr for debugging (ffmpeg output, console.error, etc.)
    Rails.logger.info("[Lambda Local #{function_name}] #{stderr}") if stderr.present?

    # Parse response
    result = JSON.parse(stdout, symbolize_names: true)

    # Check for application-level errors (same as InvokeLambda)
    raise "Lambda returned error: #{result[:error]}" if result[:error]
    raise "Lambda failed with status #{result[:statusCode]}" if result[:statusCode] != 200

    result
  rescue JSON::ParserError => e
    raise "Failed to parse Lambda response. stdout: #{stdout}, stderr: #{stderr}, error: #{e.message}"
  end

  private
  # Map function name to handler path
  memoize
  def handler_path
    case function_name
    when /video-merger/
      'services/video_production/video-merger/index.js'
    else
      raise "Unknown Lambda function: #{function_name}"
    end
  end

  # Build Node.js script that requires and invokes the handler
  memoize
  def node_script
    <<~JAVASCRIPT
      const handler = require('./#{handler_path}').handler;
      const event = JSON.parse(process.argv[1]);

      handler(event).then(result => {
        console.log(JSON.stringify(result));
        process.exit(result.statusCode === 200 ? 0 : 1);
      }).catch(error => {
        console.error('[Lambda Local Error]', error.message);
        console.error(error.stack);
        const errorResult = { error: error.message, statusCode: 500 };
        console.log(JSON.stringify(errorResult));
        process.exit(1);
      });
    JAVASCRIPT
  end

  # Get AWS settings from config gem (handles LocalStack in dev/test)
  memoize
  def aws_env
    aws_settings = JikiConfig::GenerateAwsSettings.()
    env = {
      'AWS_REGION' => aws_settings[:region]
    }
    env['AWS_ENDPOINT_URL'] = aws_settings[:endpoint] if aws_settings[:endpoint]
    env['AWS_ACCESS_KEY_ID'] = aws_settings[:access_key_id] if aws_settings[:access_key_id]
    env['AWS_SECRET_ACCESS_KEY'] = aws_settings[:secret_access_key] if aws_settings[:secret_access_key]
    env
  end
end

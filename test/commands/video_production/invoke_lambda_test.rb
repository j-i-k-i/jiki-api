require "test_helper"

class VideoProduction::InvokeLambdaTest < ActiveSupport::TestCase
  def setup
    skip "AWS Lambda SDK not installed yet" unless defined?(Aws::Lambda)
  end

  test "invokes Lambda function synchronously and returns parsed response" do
    function_name = 'jiki-video-merger-test'
    payload = { input_videos: ['s3://bucket/video1.mp4'], output_bucket: 'test-bucket', output_key: 'output.mp4' }

    # Mock Lambda client and response
    mock_client = mock('lambda_client')
    mock_response = mock('lambda_response')
    mock_response.stubs(:status_code).returns(200)
    mock_response.stubs(:function_error).returns(nil)
    mock_payload = StringIO.new('{"s3_key":"output.mp4","duration":120,"size":1024,"statusCode":200}')
    mock_response.stubs(:payload).returns(mock_payload)

    Jiki.stubs(:lambda_client).returns(mock_client)
    mock_client.expects(:invoke).with(
      function_name: function_name,
      invocation_type: 'RequestResponse',
      payload: payload.to_json
    ).returns(mock_response)

    result = VideoProduction::InvokeLambda.(function_name, payload)

    assert_equal 'output.mp4', result[:s3_key]
    assert_equal 120, result[:duration]
    assert_equal 1024, result[:size]
  end

  test "raises error when Lambda returns non-200 status" do
    function_name = 'test-function'
    payload = {}

    mock_client = mock('lambda_client')
    mock_response = mock('lambda_response')
    mock_response.stubs(:status_code).returns(500)

    Jiki.stubs(:lambda_client).returns(mock_client)
    mock_client.stubs(:invoke).returns(mock_response)

    error = assert_raises(RuntimeError) do
      VideoProduction::InvokeLambda.(function_name, payload)
    end

    assert_match(/Lambda invocation failed with status 500/, error.message)
  end

  test "raises error when Lambda returns function error" do
    function_name = 'test-function'
    payload = {}

    mock_client = mock('lambda_client')
    mock_response = mock('lambda_response')
    mock_response.stubs(:status_code).returns(200)
    mock_response.stubs(:function_error).returns('Unhandled')

    Jiki.stubs(:lambda_client).returns(mock_client)
    mock_client.stubs(:invoke).returns(mock_response)

    error = assert_raises(RuntimeError) do
      VideoProduction::InvokeLambda.(function_name, payload)
    end

    assert_match(/Lambda function error: Unhandled/, error.message)
  end

  test "raises error when Lambda response contains application error" do
    function_name = 'test-function'
    payload = {}

    mock_client = mock('lambda_client')
    mock_response = mock('lambda_response')
    mock_response.stubs(:status_code).returns(200)
    mock_response.stubs(:function_error).returns(nil)
    mock_payload = StringIO.new('{"error":"FFmpeg failed","statusCode":500}')
    mock_response.stubs(:payload).returns(mock_payload)

    Jiki.stubs(:lambda_client).returns(mock_client)
    mock_client.stubs(:invoke).returns(mock_response)

    error = assert_raises(RuntimeError) do
      VideoProduction::InvokeLambda.(function_name, payload)
    end

    assert_match(/Lambda returned error: FFmpeg failed/, error.message)
  end
end

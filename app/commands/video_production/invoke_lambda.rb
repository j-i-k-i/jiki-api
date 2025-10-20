class VideoProduction::InvokeLambda
  include Mandate

  initialize_with :function_name, :payload

  def call
    response = Jiki.lambda_client.invoke(
      function_name: function_name,
      invocation_type: 'RequestResponse', # Synchronous
      payload: JSON.generate(payload)
    )

    # Check for Lambda errors
    raise "Lambda invocation failed with status #{response.status_code}" if response.status_code != 200

    raise "Lambda function error: #{response.function_error}" if response.function_error

    # Parse response payload
    result = JSON.parse(response.payload.read, symbolize_names: true)

    # Check for application-level errors
    raise "Lambda returned error: #{result[:error]}" if result[:error]

    result
  rescue Aws::Lambda::Errors::ServiceError => e
    raise "AWS Lambda error: #{e.message}"
  end
end

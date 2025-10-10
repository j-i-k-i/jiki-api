require "test_helper"

class SPI::LLMResponsesControllerTest < ActionDispatch::IntegrationTest
  test "email_translation updates template with translated content" do
    template = create(:email_template)

    translated_content = {
      subject: "Translated Subject",
      body_mjml: "<mj-section><mj-text>Translated</mj-text></mj-section>",
      body_text: "Translated plain text"
    }

    post spi_llm_email_translation_path,
      params: {
        email_template_id: template.id,
        resp: translated_content.to_json
      },
      as: :json

    assert_response :ok

    template.reload
    assert_equal "Translated Subject", template.subject
    assert_equal "<mj-section><mj-text>Translated</mj-text></mj-section>", template.body_mjml
    assert_equal "Translated plain text", template.body_text
  end

  test "email_translation handles missing template" do
    post spi_llm_email_translation_path,
      params: {
        email_template_id: 999_999,
        resp: { subject: "Test" }.to_json
      },
      as: :json

    assert_response :not_found
    assert_equal "Email template not found", response.parsed_body["error"]
  end

  test "email_translation handles invalid JSON" do
    template = create(:email_template)

    post spi_llm_email_translation_path,
      params: {
        email_template_id: template.id,
        resp: "not valid json"
      },
      as: :json

    assert_response :unprocessable_entity
    assert_equal "Invalid JSON response", response.parsed_body["error"]
  end

  test "email_translation handles general errors" do
    template = create(:email_template)

    # Stub update! to raise an error
    EmailTemplate.any_instance.stubs(:update!).raises(StandardError.new("Database error"))

    post spi_llm_email_translation_path,
      params: {
        email_template_id: template.id,
        resp: { subject: "Test", body_mjml: "Test", body_text: "Test" }.to_json
      },
      as: :json

    assert_response :internal_server_error
    assert_equal "Internal server error", response.parsed_body["error"]
  end

  test "rate_limited logs error and returns 200" do
    post spi_llm_rate_limited_path,
      params: {
        error: "Rate limit exceeded",
        retry_after: 60,
        original_params: { email_template_id: 123 }
      },
      as: :json

    assert_response :ok
  end

  test "errored logs error and returns 200" do
    post spi_llm_errored_path,
      params: {
        error: "Invalid request",
        error_type: "invalid_request",
        original_params: { email_template_id: 123 }
      },
      as: :json

    assert_response :ok
  end
end

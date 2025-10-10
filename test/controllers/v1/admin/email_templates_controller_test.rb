require "test_helper"

module V1
  module Admin
    class EmailTemplatesControllerTest < ApplicationControllerTest
      setup do
        @admin = create(:user, :admin)
        @headers = auth_headers_for(@admin)
      end

      # Authentication guards
      guard_incorrect_token! :v1_admin_email_templates_path, method: :get
      guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :get
      guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :patch
      guard_incorrect_token! :v1_admin_email_template_path, args: [1], method: :delete

      # INDEX tests
      test "GET index returns 403 for non-admin users" do
        user = create(:user, admin: false)
        headers = auth_headers_for(user)

        get v1_admin_email_templates_path, headers:, as: :json

        assert_response :forbidden
        assert_json_response({
          error: {
            type: "forbidden",
            message: "Admin access required"
          }
        })
      end

      test "GET index returns all templates using SerializeEmailTemplates" do
        Prosopite.finish # Stop scan before creating test data
        template1 = create(:email_template, slug: "template-1", locale: "en")
        template2 = create(:email_template, slug: "template-2", locale: "hu")

        expected_templates = [
          { id: template1.id, type: "level_completion", slug: "template-1", locale: "en" },
          { id: template2.id, type: "level_completion", slug: "template-2", locale: "hu" }
        ]

        Prosopite.scan # Resume scan for the actual request
        get v1_admin_email_templates_path, headers: @headers, as: :json

        assert_response :success
        assert_json_response({
          email_templates: expected_templates
        })
      end

      test "GET index returns empty array when no templates exist" do
        get v1_admin_email_templates_path, headers: @headers, as: :json

        assert_response :success
        assert_json_response({ email_templates: [] })
      end

      # SHOW tests
      test "GET show returns 403 for non-admin users" do
        user = create(:user, admin: false)
        headers = auth_headers_for(user)
        email_template = create(:email_template)

        get v1_admin_email_template_path(email_template), headers:, as: :json

        assert_response :forbidden
      end

      test "GET show returns single template with full data using SerializeEmailTemplate" do
        email_template = create(:email_template)

        get v1_admin_email_template_path(email_template), headers: @headers, as: :json

        assert_response :success
        assert_json_response({
          email_template: {
            id: email_template.id,
            type: email_template.type,
            slug: email_template.slug,
            locale: email_template.locale,
            subject: email_template.subject,
            body_mjml: email_template.body_mjml,
            body_text: email_template.body_text
          }
        })
      end

      test "GET show returns 404 for non-existent template" do
        get v1_admin_email_template_path(id: 99_999), headers: @headers, as: :json

        assert_response :not_found
        assert_json_response({
          error: {
            type: "not_found",
            message: "Email template not found"
          }
        })
      end

      # UPDATE tests
      test "PATCH update returns 403 for non-admin users" do
        user = create(:user, admin: false)
        headers = auth_headers_for(user)
        email_template = create(:email_template)

        patch v1_admin_email_template_path(email_template),
          params: { email_template: { subject: "New Subject" } },
          headers:,
          as: :json

        assert_response :forbidden
      end

      test "PATCH update calls EmailTemplate::Update command with correct params" do
        email_template = create(:email_template)
        EmailTemplate::Update.expects(:call).with(
          email_template,
          { "subject" => "New Subject", "body_mjml" => "New MJML" }
        ).returns(email_template)

        patch v1_admin_email_template_path(email_template),
          params: {
            email_template: {
              subject: "New Subject",
              body_mjml: "New MJML"
            }
          },
          headers: @headers,
          as: :json

        assert_response :success
      end

      test "PATCH update returns updated template" do
        email_template = create(:email_template)
        new_subject = "Updated Subject"
        new_mjml = "<mj-section><mj-column><mj-text>Updated</mj-text></mj-column></mj-section>"
        new_text = "Updated text"

        patch v1_admin_email_template_path(email_template),
          params: {
            email_template: {
              subject: new_subject,
              body_mjml: new_mjml,
              body_text: new_text
            }
          },
          headers: @headers,
          as: :json

        assert_response :success

        json = response.parsed_body
        assert_equal new_subject, json["email_template"]["subject"]
        assert_equal new_mjml, json["email_template"]["body_mjml"]
        assert_equal new_text, json["email_template"]["body_text"]
      end

      test "PATCH update returns 404 for non-existent template" do
        patch v1_admin_email_template_path(id: 99_999),
          params: { email_template: { subject: "New" } },
          headers: @headers,
          as: :json

        assert_response :not_found
        assert_json_response({
          error: {
            type: "not_found",
            message: "Email template not found"
          }
        })
      end

      # DELETE tests
      test "DELETE destroy returns 403 for non-admin users" do
        user = create(:user, admin: false)
        headers = auth_headers_for(user)
        email_template = create(:email_template)

        delete v1_admin_email_template_path(email_template), headers:, as: :json

        assert_response :forbidden
      end

      test "DELETE destroy deletes template successfully" do
        email_template = create(:email_template)
        template_id = email_template.id

        assert_difference -> { EmailTemplate.count }, -1 do
          delete v1_admin_email_template_path(email_template), headers: @headers, as: :json
        end

        assert_response :no_content
        assert_nil EmailTemplate.find_by(id: template_id)
      end

      test "DELETE destroy returns 404 for non-existent template" do
        delete v1_admin_email_template_path(id: 99_999), headers: @headers, as: :json

        assert_response :not_found
        assert_json_response({
          error: {
            type: "not_found",
            message: "Email template not found"
          }
        })
      end
    end
  end
end

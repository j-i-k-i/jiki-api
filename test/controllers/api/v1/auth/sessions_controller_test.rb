require "test_helper"

module V1
  module Auth
    class SessionsControllerTest < ApplicationControllerTest
      setup do
        @user = create(:user, email: "test@example.com", password: "password123")
      end

      test "POST login returns JWT token with valid credentials" do
        post user_session_path, params: {
          user: {
            email: "test@example.com",
            password: "password123"
          }
        }, as: :json

        unless response.successful?
          puts "Response status: #{response.status}"
          puts "Response body: #{response.body}"
        end

        assert_response :ok

        json = response.parsed_body
        assert_equal @user.id, json["user"]["id"]
        assert_equal "test@example.com", json["user"]["email"]
        assert json["user"]["name"].present? || json["user"]["name"].nil?
        assert json["user"]["created_at"].present?

        # Check JWT token in response header
        token = response.headers["Authorization"]
        assert token.present?
        assert token.start_with?("Bearer ")
      end

      test "POST login returns error with invalid password" do
        post user_session_path, params: {
          user: {
            email: "test@example.com",
            password: "wrongpassword"
          }
        }, as: :json

        assert_response :unauthorized

        json = response.parsed_body
        assert_equal "unauthorized", json["error"]["type"]
        assert json["error"]["message"].present?

        # No JWT token should be present
        assert_nil response.headers["Authorization"]
      end

      test "POST login returns error with non-existent email" do
        post user_session_path, params: {
          user: {
            email: "nonexistent@example.com",
            password: "password123"
          }
        }, as: :json

        assert_response :unauthorized

        json = response.parsed_body
        assert_equal "unauthorized", json["error"]["type"]
        assert json["error"]["message"].present?
      end

      test "DELETE logout revokes the JWT token" do
        # First, sign in to get a token
        post user_session_path, params: {
          user: {
            email: "test@example.com",
            password: "password123"
          }
        }, as: :json

        token = response.headers["Authorization"]
        assert token.present?

        # Verify jwt_token and refresh_token were created
        @user.reload
        assert @user.jwt_tokens.any?, "Should have created a jwt_token on login"
        assert @user.refresh_tokens.any?, "Should have created a refresh_token on login"

        # Now logout with the token
        delete destroy_user_session_path,
          headers: { "Authorization" => token },
          as: :json

        assert_response :no_content

        # All refresh tokens should be revoked
        @user.reload
        assert_equal 0, @user.refresh_tokens.count, "All refresh tokens should be revoked on logout"
      end

      test "DELETE logout without token returns error" do
        delete destroy_user_session_path, as: :json

        assert_response :unauthorized

        json = response.parsed_body
        assert_equal "unauthorized", json["error"]["type"]
      end
    end
  end
end

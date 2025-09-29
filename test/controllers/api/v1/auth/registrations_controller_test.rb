require "test_helper"

module V1
  module Auth
    class RegistrationsControllerTest < ApplicationControllerTest
      test "POST signup creates a new user with valid params" do
        assert_difference("User.count", 1) do
          post user_registration_path, params: {
            user: {
              email: "newuser@example.com",
              password: "password123",
              password_confirmation: "password123",
              name: "New User"
            }
          }, as: :json
        end

        assert_response :created

        json = response.parsed_body
        assert_equal "newuser@example.com", json["user"]["email"]
        assert_equal "New User", json["user"]["name"]
        assert json["user"]["id"].present?
        assert json["user"]["created_at"].present?

        # Check JWT token in response header
        token = response.headers["Authorization"]
        assert token.present?
        assert token.start_with?("Bearer ")
      end

      test "POST signup returns error with invalid email" do
        assert_no_difference("User.count") do
          post user_registration_path, params: {
            user: {
              email: "invalid-email",
              password: "password123",
              password_confirmation: "password123",
              name: "New User"
            }
          }, as: :json
        end

        assert_response :unprocessable_entity

        json = response.parsed_body
        assert_equal "validation_error", json["error"]["type"]
        assert_equal "Validation failed", json["error"]["message"]
        assert json["error"]["errors"]["email"].present?
      end

      test "POST signup returns error with password mismatch" do
        assert_no_difference("User.count") do
          post user_registration_path, params: {
            user: {
              email: "newuser@example.com",
              password: "password123",
              password_confirmation: "different123",
              name: "New User"
            }
          }, as: :json
        end

        assert_response :unprocessable_entity

        json = response.parsed_body
        assert_equal "validation_error", json["error"]["type"]
        assert json["error"]["errors"]["password_confirmation"].present?
      end

      test "POST signup returns error with duplicate email" do
        create(:user, email: "existing@example.com")

        assert_no_difference("User.count") do
          post user_registration_path, params: {
            user: {
              email: "existing@example.com",
              password: "password123",
              password_confirmation: "password123",
              name: "New User"
            }
          }, as: :json
        end

        assert_response :unprocessable_entity

        json = response.parsed_body
        assert_equal "validation_error", json["error"]["type"]
        assert json["error"]["errors"]["email"].present?
      end

      test "POST signup returns error with short password" do
        assert_no_difference("User.count") do
          post user_registration_path, params: {
            user: {
              email: "newuser@example.com",
              password: "short",
              password_confirmation: "short",
              name: "New User"
            }
          }, as: :json
        end

        assert_response :unprocessable_entity

        json = response.parsed_body
        assert_equal "validation_error", json["error"]["type"]
        assert json["error"]["errors"]["password"].present?
      end
    end
  end
end

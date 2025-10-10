require "test_helper"

module V1
  module Admin
    class BaseControllerTest < ApplicationControllerTest
      # Create a test controller to test the base controller functionality
      class TestController < BaseController
        def test_action
          render json: { success: true }
        end
      end

      setup do
        # Add test route temporarily
        Rails.application.routes.draw do
          namespace :v1 do
            namespace :admin do
              get "test", to: "base_controller_test/test#test_action"
            end
          end
        end
      end

      teardown do
        # Reload the original routes
        Rails.application.reload_routes!
      end

      test "returns 401 for non-authenticated users" do
        get "/v1/admin/test", as: :json

        assert_response :unauthorized
        assert_equal "unauthorized", response.parsed_body["error"]["type"]
      end

      test "returns 403 for authenticated non-admin users" do
        user = create(:user, admin: false)
        headers = auth_headers_for(user)

        get "/v1/admin/test", headers:, as: :json

        assert_response :forbidden
        assert_json_response({
          error: {
            type: "forbidden",
            message: "Admin access required"
          }
        })
      end

      test "allows access for authenticated admin users" do
        admin = create(:user, :admin)
        headers = auth_headers_for(admin)

        get "/v1/admin/test", headers:, as: :json

        assert_response :success
        assert_json_response({ success: true })
      end
    end
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

# Configure WebMock to disable external connections
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ["127.0.0.1"]
)

# Configure Mocha to be safe
Mocha.configure do |c|
  c.stubbing_method_unnecessarily = :prevent
  c.stubbing_non_existent_method = :prevent
  c.stubbing_method_on_nil = :prevent
  c.stubbing_non_public_method = :prevent
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...

    # Helper to assert a command is idempotent
    def assert_idempotent_command
      result_one = yield
      result_two = yield
      assert_equal result_one, result_two
    end
  end
end

# Authentication helpers for API testing
module AuthenticationHelper
  def setup_user(user = nil)
    @current_user = user || create(:user)
    @auth_token = create(:auth_token, user: @current_user)
    @headers = { "Authorization" => "Bearer #{@auth_token.token}" }
  end

  def auth_headers_for(user)
    token = create(:auth_token, user: user)
    { "Authorization" => "Bearer #{token.token}" }
  end
end

# JSON response assertions
module JsonAssertions
  def assert_json_response(expected)
    actual = response.parsed_body
    assert_equal expected.deep_stringify_keys, actual
  end

  def assert_json_structure(structure, data = response.parsed_body)
    structure.each do |key, expected_type|
      assert data.key?(key.to_s), "Expected key '#{key}' in JSON response"

      if expected_type.is_a?(Hash)
        assert_json_structure(expected_type, data[key.to_s])
      elsif expected_type.is_a?(Array) && expected_type.first.is_a?(Hash)
        data[key.to_s].each do |item|
          assert_json_structure(expected_type.first, item)
        end
      elsif expected_type
        assert data[key.to_s].is_a?(expected_type),
          "Expected '#{key}' to be #{expected_type}, got #{data[key.to_s].class}"
      end
    end
  end
end

# Base test case for API controller tests
class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include AuthenticationHelper
  include JsonAssertions

  # Macro for testing authentication requirements
  def self.guard_incorrect_token!(path_helper, args: [], method: :get)
    test "#{method} #{path_helper} returns 401 with invalid token" do
      path = send(path_helper, *args)
      send(method, path, headers: { "Authorization" => "Bearer invalid" }, as: :json)

      assert_response :unauthorized
      assert_equal "invalid_auth_token", response.parsed_body["error"]["type"]
    end

    test "#{method} #{path_helper} returns 401 without token" do
      path = send(path_helper, *args)
      send(method, path, as: :json)

      assert_response :unauthorized
      assert_equal "invalid_auth_token", response.parsed_body["error"]["type"]
    end
  end
end

# Include helpers in integration tests
class ActionDispatch::IntegrationTest
  include AuthenticationHelper
  include JsonAssertions
end

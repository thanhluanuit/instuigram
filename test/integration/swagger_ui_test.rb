require "test_helper"

class SwaggerUiTest < ActionDispatch::IntegrationTest
  test "the docs page keeps only rswag-ui's own permissive policy" do
    get "/api-docs/index.html"

    assert_response :success
    policies = csp_headers
    assert_equal 1, policies.size,
      "expected one Content-Security-Policy header, got #{policies.size} — browsers enforce " \
      "the intersection, so a second policy re-blocks swagger-ui's inline script"
    assert_includes policies.sole, "'unsafe-inline'"
    assert_not_includes policies.sole, "nonce-"
  end

  test "the OpenAPI document is served for the UI to read" do
    get "/api-docs/v1/swagger.yaml"

    assert_response :success
    assert_equal "Instuigram API V1", YAML.safe_load(response.body).dig("info", "title")
  end

  test "an application page still gets the strict nonce policy" do
    get new_user_session_path

    assert_response :success
    assert_includes csp_headers.sole, "nonce-"
  end

  private

  def csp_headers
    response.headers.to_hash.filter_map do |name, value|
      value if name.casecmp?("content-security-policy")
    end
  end
end

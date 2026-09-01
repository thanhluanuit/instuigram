require "test_helper"

class Api::V1::OauthControllerTest < ActionDispatch::IntegrationTest
  test "should create token" do
    client = Client.create!(user: users(:one))

    post api_v1_oauth_path, params: {
      token: {
        client_id: client.client_id,
        client_secret: client.client_secret
      }
    }

    assert_response :created
    assert_response_schema_confirm(201)
    assert_equal "Bearer", JSON.parse(response.body)["token_type"]
    assert_not_nil JSON.parse(response.body)["access_token"]
  end

  test "should not create token with invalid credentials" do
    post api_v1_oauth_path, params: {
      token: {
        client_id: "invalid client id",
        client_secret: "invalid client secret"
      }
    }

    assert_response :unauthorized
    assert_response_schema_confirm(401)
    assert_nil JSON.parse(response.body)["access_token"]
    assert_equal "Invalid credentials", JSON.parse(response.body)["message"]
  end

  test "should not create token with the wrong secret for a valid client_id" do
    client = Client.create!(user: users(:one))

    post api_v1_oauth_path, params: {
      token: {
        client_id: client.client_id,
        client_secret: "wrong-secret"
      }
    }

    assert_response :unauthorized
    assert_response_schema_confirm(401)
    assert_equal "Invalid credentials", JSON.parse(response.body)["message"]
  end

  test "without the token parameter, responds bad request" do
    post api_v1_oauth_path, params: {}

    assert_response :bad_request
    assert_response_schema_confirm(400)
    assert_includes JSON.parse(response.body)["message"], "token"
  end
end

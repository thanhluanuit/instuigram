require "test_helper"

class Api::V1::OauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    Api::V1::OauthController.cache_store.clear
  end

  test "should create token" do
    client = Client.create!(user: users(:one))

    post api_v1_oauth_path, params: {
      token: {
        client_id: client.client_id,
        client_secret: client.client_secret
      }
    }

    assert_response :created
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
    assert_equal "Invalid credentials", JSON.parse(response.body)["message"]
  end

  test "throttles repeated attempts, so client secrets cannot be brute forced" do
    client = Client.create!(user: users(:one))

    10.times do
      post api_v1_oauth_path, params: { token: { client_id: client.client_id, client_secret: "wrong-secret" } }
      assert_response :unauthorized
    end

    post api_v1_oauth_path, params: { token: { client_id: client.client_id, client_secret: client.client_secret } }

    assert_response :too_many_requests
    assert_equal({ "message" => "Too many attempts. Try again later." }, JSON.parse(response.body))
  end
end

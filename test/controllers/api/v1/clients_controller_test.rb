require "test_helper"

class Api::V1::ClientsControllerTest < ActionDispatch::IntegrationTest
  test "with valid credentials, creates a client owned by that user and returns its id and secret" do
    assert_difference("Client.count", 1) do
      post api_v1_clients_path, params: { email: users(:one).email, password: "password123" }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal Client.last.client_id, body["client_id"]
    assert Client.last.authenticate_client_secret(body["client_secret"])
    assert_equal users(:one), Client.last.user
  end

  test "with a wrong password, responds unauthorized with a generic message and creates no client" do
    assert_no_difference("Client.count") do
      post api_v1_clients_path, params: { email: users(:one).email, password: "wrongpassword" }
    end

    assert_response :unauthorized
    assert_equal({ "message" => "Invalid email or password" }, JSON.parse(response.body))
  end

  test "with a nonexistent email, responds with the same generic message as a wrong password" do
    post api_v1_clients_path, params: { email: "nobody@example.com", password: "whatever" }

    assert_response :unauthorized
    assert_equal({ "message" => "Invalid email or password" }, JSON.parse(response.body))
  end

  test "throttles repeated attempts, so the endpoint cannot be used to guess a password" do
    5.times do
      post api_v1_clients_path, params: { email: users(:one).email, password: "wrongpassword" }
      assert_response :unauthorized
    end

    assert_no_difference("Client.count") do
      post api_v1_clients_path, params: { email: users(:one).email, password: "password123" }
    end

    assert_response :too_many_requests
    assert_equal({ "message" => "Too many attempts. Try again later." }, JSON.parse(response.body))
  end
end

require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "generates a UUID client_id on create" do
    client = Client.create!(user: users(:one))

    assert_match(/\A[0-9a-f-]{36}\z/, client.client_id)
  end

  test "generates a different client_id and client_secret per client" do
    client_one = Client.create!(user: users(:one))
    client_two = Client.create!(user: users(:two))

    assert_not_equal client_one.client_id, client_two.client_id
    assert_not_equal client_one.client_secret, client_two.client_secret
  end

  test "authenticate_client_secret returns the client for the correct secret" do
    client = Client.create!(user: users(:one))
    client_secret = client.client_secret

    assert_equal client, client.authenticate_client_secret(client_secret)
  end

  test "authenticate_client_secret returns false for an incorrect secret" do
    client = Client.create!(user: users(:one))

    assert_equal false, client.authenticate_client_secret("wrong-secret")
  end

  test "a user can have more than one client" do
    Client.create!(user: users(:one))
    Client.create!(user: users(:one))

    assert_equal 2, users(:one).clients.count
  end
end

require "test_helper"

class PostChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for the post when given a valid post key" do
    stub_connection(current_user: nil)
    subscribe(id: posts(:one).key)

    assert subscription.confirmed?
    assert_has_stream_for posts(:one)
  end

  test "rejects the subscription when the post key does not exist" do
    stub_connection(current_user: nil)
    subscribe(id: -1)

    assert subscription.rejected?
  end

  test "rejects the subscription when a post is addressed by its database id" do
    stub_connection(current_user: nil)
    subscribe(id: posts(:one).id)

    assert subscription.rejected?
  end

  test "also streams for the current user's own reaction state when authenticated" do
    stub_connection(current_user: users(:one))
    subscribe(id: posts(:one).key)

    assert subscription.confirmed?
    assert_has_stream_for [ posts(:one), users(:one) ]
  end

  test "does not stream for a private reaction state when anonymous" do
    stub_connection(current_user: nil)
    subscribe(id: posts(:one).key)

    assert subscription.confirmed?
    assert_has_no_stream_for [ posts(:one), users(:one) ]
  end
end

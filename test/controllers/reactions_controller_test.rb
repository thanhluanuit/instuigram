require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  test "when unauthenticated, redirects to sign in and creates no reaction" do
    assert_no_difference("Reaction.count") { post post_reaction_path(posts(:one)) }

    assert_redirected_to new_user_session_path
  end

  test "when authenticated, creates a like reaction owned by current_user and redirects to the post" do
    sign_in users(:one)

    assert_difference("Reaction.count", 1) { post post_reaction_path(posts(:two)) }

    reaction = Reaction.last
    assert_equal users(:one), reaction.user
    assert_equal posts(:two), reaction.reactable
    assert reaction.like?
    assert_redirected_to post_path(posts(:two))
  end

  test "when already reacted, reacting again does not create a second reaction" do
    sign_in users(:two)

    assert_no_difference("Reaction.count") { post post_reaction_path(posts(:one)) }
  end

  test "when a valid reaction_type param is given, uses it instead of the default" do
    sign_in users(:one)

    post post_reaction_path(posts(:two)), params: { reaction_type: "love" }

    assert_equal "love", Reaction.last.reaction_type
  end

  test "when an unrecognized reaction_type param is given, falls back to like" do
    sign_in users(:one)

    post post_reaction_path(posts(:two)), params: { reaction_type: "not_a_real_type" }

    assert_equal "like", Reaction.last.reaction_type
  end

  test "when unauthenticated, redirects to sign in and does not delete a reaction" do
    assert_no_difference("Reaction.count") { delete post_reaction_path(posts(:one)) }

    assert_redirected_to new_user_session_path
  end

  test "when authenticated, deletes the user's own reaction and redirects to the post" do
    sign_in users(:two)

    assert_difference("Reaction.count", -1) { delete post_reaction_path(posts(:one)) }

    assert_redirected_to post_path(posts(:one))
  end

  test "when the user has no reaction on the post, destroy is a no-op" do
    sign_in users(:one)

    assert_no_difference("Reaction.count") { delete post_reaction_path(posts(:two)) }

    assert_redirected_to post_path(posts(:two))
  end

  test "when creating from a referring page, redirects back there instead of the post" do
    sign_in users(:one)

    post post_reaction_path(posts(:two)), headers: { "HTTP_REFERER" => root_path }

    assert_redirected_to root_path
  end

  test "when destroying from a referring page, redirects back there instead of the post" do
    sign_in users(:two)

    delete post_reaction_path(posts(:one)), headers: { "HTTP_REFERER" => root_path }

    assert_redirected_to root_path
  end
end

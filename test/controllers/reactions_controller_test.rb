require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "when unauthenticated, redirects to sign in and creates no reaction" do
    assert_no_difference([ "Reaction.count", "EventLog.count" ]) { post post_reaction_path(posts(:one)) }

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

  test "when authenticated, logs a reaction_created event for a first-time reaction" do
    sign_in users(:one)

    assert_difference("EventLog.count", 1) { perform_enqueued_jobs { post post_reaction_path(posts(:two)) } }

    event_log = EventLog.last
    assert_equal "reaction_created", event_log.event_type
    assert_equal Reaction.last, event_log.subject
    assert_equal users(:one), event_log.user
  end

  test "when already reacted, reacting again does not create a second reaction" do
    sign_in users(:two)

    assert_no_difference("Reaction.count") { post post_reaction_path(posts(:one)) }
  end

  test "when already reacted, changing the reaction_type does not log a new reaction_created event" do
    sign_in users(:two)

    assert_no_difference("EventLog.count") do
      post post_reaction_path(posts(:one)), params: { reaction_type: "love" }
    end
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

  test "when creating from the popup's reaction frame, redirects to the post so the popup re-renders" do
    sign_in users(:one)

    post post_reaction_path(posts(:two)),
         headers: { "HTTP_REFERER" => root_path, "Turbo-Frame" => dom_id(posts(:two), :modal_reaction) }

    assert_redirected_to post_path(posts(:two))
  end

  test "when destroying from the popup's reaction frame, redirects to the post so the popup re-renders" do
    sign_in users(:two)

    delete post_reaction_path(posts(:one)),
           headers: { "HTTP_REFERER" => root_path, "Turbo-Frame" => dom_id(posts(:one), :modal_reaction) }

    assert_redirected_to post_path(posts(:one))
  end

  test "responds not found when the post being reacted to is addressed by its database id" do
    sign_in users(:one)

    assert_no_difference("Reaction.count") { post post_reaction_path(post_id: posts(:two).id) }

    assert_response :not_found
  end

  test "when signed in as a different user, destroying leaves their reaction in place" do
    sign_in users(:one)

    delete post_reaction_path(posts(:one))

    assert Reaction.exists?(reactions(:one).id)
  end
end

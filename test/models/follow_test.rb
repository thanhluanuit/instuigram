require "test_helper"

class FollowTest < ActiveSupport::TestCase
  setup do
    @follower = users(:one)
    @followed = users(:two)
  end

  test "is valid with a follower and a followed user" do
    assert build_follow.valid?
  end

  test "is invalid when a user follows themselves" do
    follow = build_follow(followed: @follower)

    assert_not follow.valid?
    assert_includes follow.errors[:followed_id], "can't be yourself"
  end

  test "the database rejects a self-follow even when the validation is bypassed" do
    follow = build_follow(followed: @follower)

    assert_raises(ActiveRecord::StatementInvalid) { follow.save!(validate: false) }
  end

  test "is invalid when the same user follows the same user twice" do
    build_follow.save!
    duplicate = build_follow

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:follower_id], "has already been taken"
  end

  test "allows the reverse follow back" do
    build_follow.save!

    assert build_follow(follower: @followed, followed: @follower).valid?
  end

  test "creating a follow increments the followed user's followers_count" do
    assert_difference(-> { @followed.reload.followers_count }, 1) do
      build_follow.save!
    end
  end

  test "creating a follow increments the follower's following_count" do
    assert_difference(-> { @follower.reload.following_count }, 1) do
      build_follow.save!
    end
  end

  test "destroying a follow decrements both counter caches" do
    follow = build_follow
    follow.save!

    assert_difference([ -> { @followed.reload.followers_count }, -> { @follower.reload.following_count } ], -1) do
      follow.destroy
    end
  end

  test "following? is true only for a user the follower actually follows" do
    build_follow.save!

    assert @follower.following?(@followed)
    assert_not @followed.following?(@follower)
    assert_not @follower.following?(users(:admin))
  end

  test "following and followers expose both sides of the graph" do
    build_follow.save!

    assert_equal [ @followed ], @follower.reload.following.to_a
    assert_equal [ @follower ], @followed.reload.followers.to_a
  end

  test "destroying a user removes the follows in both directions" do
    build_follow.save!
    build_follow(follower: users(:admin), followed: @follower).save!

    assert_difference("Follow.count", -2) { @follower.destroy }
  end

  test "destroying a user leaves the other users' counter caches correct" do
    build_follow.save!
    build_follow(follower: @follower, followed: users(:admin)).save!

    @follower.destroy

    assert_equal 0, @followed.reload.followers_count
    assert_equal 0, users(:admin).reload.followers_count
  end

  private

  def build_follow(follower: @follower, followed: @followed)
    Follow.new(follower: follower, followed: followed)
  end
end

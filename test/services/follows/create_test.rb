require "test_helper"

class Follows::CreateTest < ActiveSupport::TestCase
  setup do
    @follower = users(:one)
    @followed = users(:two)
  end

  test "creates a follow between the two users" do
    follow = assert_difference("Follow.count", 1) { create_follow }

    assert follow.persisted?
    assert_equal @follower, follow.follower
    assert_equal @followed, follow.followed
    assert follow.previously_new_record?
  end

  test "following again returns the existing follow without creating a second" do
    existing = create_follow

    follow = assert_no_difference("Follow.count") { create_follow }

    assert_equal existing, follow
    assert_not follow.previously_new_record?
  end

  test "returns the winning row when a concurrent request wins the insert race" do
    follow = losing_the_insert_race { create_follow }

    assert follow.persisted?
    assert_equal 1, Follow.where(follower: @follower, followed: @followed).count
  end

  private

  def create_follow(follower: @follower, followed: @followed)
    Follows::Create.call(follower: follower, followed: followed)
  end

  def losing_the_insert_race(follower: @follower, followed: @followed)
    Follow.define_singleton_method(:create!) do |*|
      insert_all([ { follower_id: follower.id, followed_id: followed.id,
                     created_at: Time.current, updated_at: Time.current } ])
      raise ActiveRecord::RecordNotUnique, "duplicate key value violates unique constraint"
    end

    yield
  ensure
    Follow.singleton_class.remove_method(:create!)
  end
end

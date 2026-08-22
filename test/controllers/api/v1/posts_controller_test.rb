require "test_helper"

class Api::V1::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @client = Client.create!(user: @user)
    @token = encode_access_token(@client)
  end

  test "index without a token is unauthorized" do
    get api_v1_posts_path

    assert_response :unauthorized
  end

  test "index returns only the current user's posts" do
    get api_v1_posts_path, headers: auth_headers

    assert_response :success
    ids = JSON.parse(response.body)["posts"].map { |post| post["id"] }
    assert_includes ids, posts(:one).id
    assert_not_includes ids, posts(:two).id
  end

  test "index paginates results to 25 per page" do
    26.times { |n| create_post!(@user, description: "post #{n}") }

    get api_v1_posts_path, headers: auth_headers

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 25, body["posts"].size
    assert_equal 1, body["current_page"]
    assert_equal 2, body["total_pages"]
  end

  test "show returns the post's attributes" do
    get api_v1_post_path(posts(:one)), headers: auth_headers

    assert_response :success
    assert_equal posts(:one).description, JSON.parse(response.body)["description"]
  end

  test "show for another user's post responds not found" do
    get api_v1_post_path(posts(:two)), headers: auth_headers

    assert_response :not_found
  end

  test "create with valid params creates a post owned by the token's user" do
    assert_difference("Post.count", 1) do
      post api_v1_posts_path,
        params: { post: { description: "hello #world", image: fixture_file_upload("test_image.png", "image/png") } },
        headers: auth_headers
    end

    assert_response :created
    assert_equal @user, Post.last.user
  end

  test "create without an image returns unprocessable_entity and creates no post" do
    assert_no_difference("Post.count") do
      post api_v1_posts_path, params: { post: { description: "no image" } }, headers: auth_headers
    end

    assert_response :unprocessable_entity
  end

  test "destroy removes the current user's own post" do
    own_post = create_post!(@user, description: "mine")

    assert_difference("Post.count", -1) do
      delete api_v1_post_path(own_post), headers: auth_headers
    end

    assert_response :no_content
  end

  test "destroy on another user's post responds not found and does not delete it" do
    delete api_v1_post_path(posts(:two)), headers: auth_headers

    assert_response :not_found
    assert Post.exists?(posts(:two).id)
  end

  private

  def auth_headers
    { "Authorization" => "Bearer #{@token}" }
  end

  def encode_access_token(client)
    JWT.encode(
      { sub: client.client_id, iat: Time.current.to_i, exp: 1.hour.from_now.to_i },
      Rails.application.credentials.jwt_secret_key, "HS256"
    )
  end
end

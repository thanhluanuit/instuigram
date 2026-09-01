# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { User.create!(email: "docs@instuigram.com", password: "password123") }
  let(:other_user) { User.create!(email: "someone-else@instuigram.com", password: "password123") }
  let(:client) { Client.create!(user: user) }
  let(:Authorization) { "Bearer #{issue_access_token(client)}" }

  def build_post(owner, description: "a sunset over the bay #sunset")
    post = owner.posts.new(description: description)
    post.image.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
      filename: "test_image.png", content_type: "image/png"
    )
    post.save!
    post
  end

  path "/api/v1/posts" do
    get "Lists the authenticated user's posts" do
      tags "Posts"
      description "Newest first, ten per page. Only posts owned by the token's user are returned."
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :page, in: :query, required: false, schema: { type: :integer, minimum: 1 }

      let(:page) { 1 }

      response "200", "posts listed" do
        schema "$ref" => "#/components/schemas/PostsPage"

        before do
          build_post(user)
          build_post(other_user)
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["posts"].map { |p| p["id"] }).to eq(user.posts.pluck(:id))
          expect(body["current_page"]).to eq(1)
          expect(body["total_pages"]).to eq(1)
        end
      end

      response "401", "missing or invalid bearer token" do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "Bearer not-a-real-token" }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Unauthorized")
        end
      end
    end

    post "Creates a post for the authenticated user" do
      tags "Posts"
      description "Multipart upload. An image is required; hashtags are parsed out of the description."
      consumes "multipart/form-data"
      produces "application/json"
      security [ bearer_auth: [] ]

      parameter name: :post, in: :formData, getter: :post_body, required: true, schema: {
        type: :object,
        properties: {
          "post[image]": { type: :string, format: :binary },
          "post[description]": { type: :string, maxLength: 2200 }
        },
        required: [ "post[image]" ]
      }

      let(:image_upload) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("test/fixtures/files/test_image.png"), "image/png"
        )
      end

      response "201", "post created" do
        schema "$ref" => "#/components/schemas/Post"

        let(:post_body) do
          { description: "a sunset over the bay #sunset", image: image_upload }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(Post.find(body["id"]).user).to eq(user)
          expect(body["hash_tags"]).to eq([ "sunset" ])
          expect(body["image_url"]).to be_present
        end
      end

      response "422", "image missing" do
        schema "$ref" => "#/components/schemas/Error"

        let(:post_body) { { description: "no image attached" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to include("Image")
          expect(user.posts.count).to eq(0)
        end
      end
    end
  end

  path "/api/v1/posts/{id}" do
    parameter name: :id, in: :path, required: true, schema: { type: :integer }

    get "Shows one of the authenticated user's posts" do
      tags "Posts"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "200", "post found" do
        schema "$ref" => "#/components/schemas/Post"

        let(:id) { build_post(user).id }

        run_test! do |response|
          expect(JSON.parse(response.body)["description"]).to eq("a sunset over the bay #sunset")
        end
      end

      response "404", "post belongs to another user" do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { build_post(other_user).id }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Not found")
        end
      end
    end

    delete "Deletes one of the authenticated user's posts" do
      tags "Posts"
      produces "application/json"
      security [ bearer_auth: [] ]

      response "204", "post deleted" do
        let(:id) { build_post(user).id }

        run_test! do
          expect(Post.exists?(id)).to be(false)
        end
      end

      response "404", "post belongs to another user" do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { build_post(other_user).id }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Not found")
          expect(Post.exists?(id)).to be(true)
        end
      end
    end
  end
end

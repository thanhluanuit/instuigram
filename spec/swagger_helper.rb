# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Instuigram API V1",
        version: "v1",
        description: "Register a client with a user's credentials, exchange it for a " \
                     "bearer token, then read and write that user's posts."
      },
      servers: [
        { url: "http://localhost:3000", description: "Development" }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          Error: {
            type: :object,
            additionalProperties: false,
            properties: {
              message: { type: :string, example: "Not found" }
            },
            required: %w[message]
          },
          ClientCredentials: {
            type: :object,
            additionalProperties: false,
            properties: {
              client_id: { type: :string, format: :uuid },
              client_secret: {
                type: :string,
                description: "Returned only once, at creation time. It is stored hashed."
              }
            },
            required: %w[client_id client_secret]
          },
          AccessToken: {
            type: :object,
            additionalProperties: false,
            properties: {
              token_type: { type: :string, example: "Bearer" },
              expires_in: { type: :integer, example: 3600 },
              access_token: { type: :string }
            },
            required: %w[token_type expires_in access_token]
          },
          Post: {
            type: :object,
            additionalProperties: false,
            properties: {
              id: { type: :integer },
              description: { type: :string, nullable: true },
              image_url: { type: :string, nullable: true },
              hash_tags: { type: :array, items: { type: :string } },
              created_at: { type: :string, format: :"date-time" }
            },
            required: %w[id description image_url hash_tags created_at]
          },
          PostsPage: {
            type: :object,
            additionalProperties: false,
            properties: {
              posts: { type: :array, items: { "$ref" => "#/components/schemas/Post" } },
              current_page: { type: :integer },
              total_pages: { type: :integer }
            },
            required: %w[posts current_page total_pages]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end

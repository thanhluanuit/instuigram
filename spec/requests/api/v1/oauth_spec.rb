# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Oauth", type: :request do
  path "/api/v1/oauth" do
    post "Exchanges client credentials for an access token" do
      tags "Oauth"
      description "Returns a bearer token valid for one hour. Send it as " \
                  "`Authorization: Bearer <access_token>` on every posts request."
      consumes "application/json"
      produces "application/json"

      parameter name: :token_request, in: :body, schema: {
        type: :object,
        properties: {
          token: {
            type: :object,
            properties: {
              client_id: { type: :string, format: :uuid },
              client_secret: { type: :string }
            },
            required: %w[client_id client_secret]
          }
        },
        required: %w[token]
      }

      let(:user) { User.create!(email: "docs@instuigram.com", password: "password123") }
      let(:client) { Client.create!(user: user) }

      response "201", "access token issued" do
        schema "$ref" => "#/components/schemas/AccessToken"

        let(:token_request) do
          { token: { client_id: client.client_id, client_secret: client.client_secret } }
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["token_type"]).to eq("Bearer")
          expect(body["expires_in"]).to eq(3600)
          payload, = JWT.decode(
            body["access_token"], Rails.application.credentials.jwt_secret_key,
            true, algorithm: "HS256"
          )
          expect(payload["sub"]).to eq(client.client_id)
        end
      end

      response "401", "invalid client credentials" do
        schema "$ref" => "#/components/schemas/Error"

        let(:token_request) do
          { token: { client_id: client.client_id, client_secret: "wrong-secret" } }
        end

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Invalid credentials")
        end
      end

      response "400", "token parameter missing" do
        schema "$ref" => "#/components/schemas/Error"

        let(:token_request) { {} }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to include("token")
        end
      end
    end
  end
end

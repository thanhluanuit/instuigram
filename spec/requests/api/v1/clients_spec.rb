# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Clients", type: :request do
  path "/api/v1/clients" do
    post "Registers an API client for a user" do
      tags "Clients"
      description "Exchanges a user's sign-in credentials for a client id and secret. " \
                  "The secret is returned only in this response and is stored hashed."
      consumes "application/json"
      produces "application/json"

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string, format: :password }
        },
        required: %w[email password]
      }

      let(:user) { User.create!(email: "docs@instuigram.com", password: "password123") }

      response "201", "client registered" do
        schema "$ref" => "#/components/schemas/ClientCredentials"

        let(:credentials) { { email: user.email, password: "password123" } }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["client_id"]).to eq(user.clients.sole.client_id)
          expect(body["client_secret"]).to be_present
        end
      end

      response "401", "invalid email or password" do
        schema "$ref" => "#/components/schemas/Error"

        let(:credentials) { { email: user.email, password: "wrong-password" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["message"]).to eq("Invalid email or password")
        end
      end
    end
  end
end

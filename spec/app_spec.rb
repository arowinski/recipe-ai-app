# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require "./app"
require "rspec"
require "rack/test"

RSpec.describe "App" do
  include Rack::Test::Methods

  def app
    App
  end

  describe "GET /" do
    it "returns index file" do
      get "/"

      expect(last_response).to be_ok
      expect(last_response.body).to include("Get Recipe")
    end
  end

  describe "POST /api/recipe" do
    it "returns OK status and JSON with recipe" do
      allow(RecipeService).to receive(:from_ingredients).with("water, bananas")
        .and_return(RecipeService::Response.new(status: :ok, message: "recipe"))

      post "/api/recipe", {ingredients: "water, bananas"}.to_json, "CONTENT_TYPE" => "application/json"

      expect(last_response).to be_ok
      expect(last_response.body).to eq({message: "recipe"}.to_json)
    end

    context "when ingredients param is not provided" do
      it "returns bad request with error message" do
        post "/api/recipe", {}.to_json, "CONTENT_TYPE" => "application/json"

        expect(last_response).to be_bad_request
        expect(last_response.body).to eq({message: "Please provide a list of ingredients."}.to_json)
      end
    end

    context "when request payload is invalid" do
      it "returns not found with error message" do
        post "/api/recipe", "<xml></xml>", "CONTENT_TYPE" => "application/json"

        expect(last_response).to be_bad_request
        expect(last_response.body).to eq({message: "Please provide a list of ingredients."}.to_json)
      end
    end

    context "when recipe service returns an error" do
      it "returns unprocessable entity with error message" do
        allow(RecipeService).to receive(:from_ingredients).with("water, bananas")
          .and_return(RecipeService::Response.new(status: :error, message: "error"))

        post "/api/recipe", {ingredients: "water, bananas"}.to_json, "CONTENT_TYPE" => "application/json"

        expect(last_response).to be_unprocessable
        expect(last_response.body).to eq({message: "error"}.to_json)
      end
    end

    context "when recipe is not valid" do
      it "returns not found with error message" do
        allow(RecipeService).to receive(:from_ingredients).with("water, bananas")
          .and_return(RecipeService::Response.new(status: :invalid, message: "error"))

        post "/api/recipe", {ingredients: "water, bananas"}.to_json, "CONTENT_TYPE" => "application/json"

        expect(last_response).to be_not_found
        expect(last_response.body).to eq({message: "error"}.to_json)
      end
    end
  end
end

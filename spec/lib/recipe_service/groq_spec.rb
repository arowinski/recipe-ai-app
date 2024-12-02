require "webmock/rspec"
require "./lib/recipe_service/groq"

RSpec.describe RecipeService::Groq do
  before do
    # Silence logs in the tests
    RecipeService::LOGGER.level = 4
  end

  describe ".ask" do
    it "returns an OK response" do
      stub_request(:post, described_class::ENDPOINT)
        .with(
          body: {
            messages: [
              {role: "system", content: described_class::RECIPE_PROMPT},
              {role: "user", content: "potato, tomato"}
            ],
            temperature: described_class::DEFAULT_TEMPERATURE,
            model: described_class::DEFAULT_MODEL
          }.to_json
        )
        .to_return(status: 200, body: {choices: [{message: {content: "recipe"}}]}.to_json)

      response = described_class.ask("potato, tomato")

      expect(response).to be_ok.and have_attributes(message: "recipe")
    end

    context "when Groq API responds with non OK status" do
      it "returns an error response" do
        stub_request(:post, described_class::ENDPOINT)
          .to_return(status: 400, body: {choices: [{message: {content: "recipe"}}]}.to_json)

        response = described_class.ask("potato, tomato")

        expect(response).not_to be_ok
      end

      it "logs the error" do
        stub_request(:post, described_class::ENDPOINT)
          .to_return(status: 400, body: {error: "error msg"}.to_json)

        allow(RecipeService::LOGGER).to receive(:error)

        described_class.ask("potato, tomato")

        expect(RecipeService::LOGGER).to have_received(:error).with({error: "error msg"}.to_json)
      end
    end
  end

  describe ".validate" do
    def stub_groq_chat_completions(input:, status:, response_content: "0")
      stub_request(:post, described_class::ENDPOINT)
        .with(
          body: {
            messages: [
              {role: "system", content: described_class::VALIDATION_PROMPT},
              {role: "user", content: input}
            ],
            temperature: 0.05,
            model: described_class::DEFAULT_MODEL
          }.to_json
        )
        .to_return(status:, body: {choices: [{message: {content: response_content}}]}.to_json)
    end

    context "when Groq API returns 0 as content" do
      it "returns true" do
        stub_groq_chat_completions(input: "recipe", status: 200, response_content: "0")

        response = described_class.validate("recipe")

        expect(response).to be(true)
      end
    end

    context "when Groq API returns 1 as content" do
      it "returns true" do
        stub_groq_chat_completions(input: "recipe", status: 200, response_content: "1")

        response = described_class.validate("recipe")

        expect(response).to be(false)
      end
    end

    context "when Groq API responds with non OK status" do
      it "returns error response" do
        stub_groq_chat_completions(input: "recipe", status: 400)

        response = described_class.validate("recipe")

        expect(response).to be(false)
      end

      it "logs the error" do
        stub_groq_chat_completions(input: "recipe", status: 400, response_content: "error content")

        allow(RecipeService::LOGGER).to receive(:error)

        described_class.validate("recipe")

        expect(RecipeService::LOGGER).to have_received(:error).with(include("error content"))
      end
    end

    context "when Groq API responds with unexpected message" do
      it "returns false" do
        stub_groq_chat_completions(input: "recipe", status: 200, response_content: "valid")

        response = described_class.validate("recipe")

        expect(response).to be(false)
      end
    end
  end
end

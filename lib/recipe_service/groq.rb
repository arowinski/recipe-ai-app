require "net/http"
require "uri"
require "json"
require "logger"

# NOTE: This is naive implementation, lacks a.o. exponential backoff, rate limiting
#       and robust error handling (HTTP request, JSON parsing and content accessing).

class RecipeService
  Response = Data.define(:status, :message) do
    def ok? = status == :ok
  end

  LOGGER = Logger.new($stdout)

  class Groq
    ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions")
    DEFAULT_MODEL = "llama3-8b-8192"
    DEFAULT_TEMPERATURE = 0.7

    RECIPE_PROMPT = <<~PROMPT.strip.tr("\n", " ")
      You are a culinary expert with deep knowledge of global cuisines.
      Given a list of ingredients, provide a practical recipe with step-by-step instructions, 
      cooking methods, and optional substitutions.
    PROMPT

    VALIDATION_PROMPT = <<~PROMPT.strip.tr("\n", " ")
      You are a culinary expert with extensive knowledge of global cuisines.
      Given a recipe, return exactly 0 if it is a valid recipe, or exactly 1 if it is not.
    PROMPT

    class << self
      def ask(ingredients)
        chat(
          messages: [
            {role: "system", content: RECIPE_PROMPT},
            {role: "user", content: ingredients}
          ]
        )
      end

      def validate(recipe)
        result = chat(
          messages: [
            {role: "system", content: VALIDATION_PROMPT},
            {role: "user", content: recipe}
          ],
          temperature: 0.05
        )

        result.status == :ok && result.message == "0"
      end

      private

      def chat(messages:, temperature: DEFAULT_TEMPERATURE)
        response = request_completion(messages:, temperature:)

        if response.code == "200"
          Response.new(status: :ok, message: extract_content(response))
        else
          LOGGER.error(response.body)
          Response.new(status: :error, message: nil)
        end
      end

      def request_completion(messages:, temperature:, model: DEFAULT_MODEL)
        Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, max_retries: 2) do |http|
          req = Net::HTTP::Post.new(ENDPOINT)
          req["Content-Type"] = "application/json"
          req["Authorization"] = "Bearer #{ENV["GROQ_API_KEY"]}"
          req.body = {messages:, temperature:, model:}.to_json
          http.request(req)
        end
      end

      def extract_content(response)
        json = JSON.parse(response.body)
        json.dig("choices", 0, "message", "content")
      end
    end
  end
end

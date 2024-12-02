require "./lib/recipe_service/groq"

class RecipeService
  class << self
    def from_ingredients(ingredients, provider: RecipeService::Groq, validator: provider)
      result = provider.ask(ingredients)

      if result.ok?
        process_ok_response(result, validator:)
      else
        handle_invalid_response
      end
    end

    private

    def process_ok_response(result, validator:)
      return result if validator.nil?

      validator.validate(result.message) ? result : handle_invalid_recipe
    end

    def handle_invalid_recipe
      Response.new(
        status: :invalid,
        message: "I'm sorry, We couldn't find a recipe for that combination of ingredients."
      )
    end

    def handle_invalid_response
      Response.new(
        status: :service_error,
        message: "We have encountered an error. Please try again later."
      )
    end
  end
end

require "./lib/recipe_service"

RSpec.describe RecipeService do
  describe ".from_ingredients" do
    it "returns a valid recipe" do
      ingredients = "potato, tomato"
      provider = double
      allow(provider).to receive(:ask).with(ingredients)
        .and_return(described_class::Response.new(status: :ok, message: "1"))

      response = described_class.from_ingredients(ingredients, provider:, validator: nil)

      expect(response).to be_ok.and have_attributes(message: "1")
    end

    context "when validator given" do
      context "and recipe is valid" do
        it "returns recipe" do
          ingredients = "potato, tomato"
          provider = double
          allow(provider).to receive(:ask).with(ingredients)
            .and_return(described_class::Response.new(status: :ok, message: "recipe"))
          allow(provider).to receive(:validate).with("recipe").and_return(true)

          response = described_class.from_ingredients(ingredients, provider:, validator: provider)

          expect(response).to be_ok.and have_attributes(message: "recipe")
        end
      end

      context "and recipe is invalid" do
        it "returns nil" do
          ingredients = "potato, tomato"
          provider = double
          allow(provider).to receive(:ask).with(ingredients)
            .and_return(described_class::Response.new(status: :ok, message: "recipe"))
          allow(provider).to receive(:validate).with("recipe").and_return(false)

          response = described_class.from_ingredients(ingredients, provider:, validator: provider)

          expect(response).not_to be_ok
          expect(response).to have_attributes(
            message: "I'm sorry, We couldn't find a recipe for that combination of ingredients."
          )
        end
      end
    end

    context "when recipe provider returned error" do
      it "returns error with message" do
        ingredients = "potato, tomato"
        provider = double
        allow(provider).to receive(:ask).with(ingredients)
          .and_return(described_class::Response.new(status: :error, message: "recipe"))

        response = described_class.from_ingredients(ingredients, provider:, validator: provider)

        expect(response).not_to be_ok
        expect(response).to have_attributes(message: "We have encountered an error. Please try again later.")
      end
    end
  end
end

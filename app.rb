require "sinatra"
require "sinatra/json"
require "./lib/recipe_service"

class App < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + "/public"

  helpers do
    def http_status_from_response(response)
      return 200 if response.ok?

      (response.status == :invalid) ? 404 : 422
    end

    def parse_body
      JSON.parse(request.body.read)
    rescue JSON::ParserError
      {}
    end
  end

  get "/" do
    send_file File.join(settings.public_folder, "index.html")
  end

  post "/api/recipe" do
    payload = parse_body

    if payload["ingredients"].nil? || payload["ingredients"].empty?
      status 400
      json message: "Please provide a list of ingredients."
    else
      response = RecipeService.from_ingredients(payload["ingredients"])

      status http_status_from_response(response)
      json message: response.message
    end
  end

  run! if app_file == $0
end

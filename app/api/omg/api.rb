require 'grape_logging'

module OMG
  class API < Grape::API

    logger.formatter = GrapeLogging::Formatters::Default.new
    insert_before Grape::Middleware::Error, GrapeLogging::Middleware::RequestLogger, { logger: logger }

    helpers OMG::Helpers::RequestHelpers

    format :json
    prefix :api

    # Format:
    # {
    #     "error": [
    #         "id is invalid"
    #     ]
    # }
    rescue_from Grape::Exceptions::ValidationErrors do |e|
      # Rails.logger.error("ValidationError during Grape endpoint: #{e.message}")
      error! e.message, 400
    end

    rescue_from :all do |e|
      # Rails.logger.error("Error during Grape endpoint: #{e.message}\nBacktrace: #{e.backtrace.first(10).join("\n")}")
      Sentry.capture_exception(e)
      error! e.message
    end

    mount Players
    mount Doctrines
    mount Factions
    mount Companies
    mount SnapshotCompanies
    mount Units
    mount Battles
    mount Restrictions
    mount Chat
    mount Leaderboard
    mount Rulesets
    mount Stats

    route :any, '*path' do
      error! "Not implemented", 404
    end
  end
end


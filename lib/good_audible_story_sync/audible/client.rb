# frozen_string_literal: true

require "httparty"

module GoodAudibleStorySync
  module Audible
    class Client
      def initialize(auth:)
        @auth = auth
      end

      def get_library
        response = HTTParty.get("#{api_url}/1.0/library")
      end

      private

      def api_url
        "https://api.audible.com"
      end
    end
  end
end

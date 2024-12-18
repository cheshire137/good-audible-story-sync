# frozen_string_literal: true

require "httparty"

module GoodAudibleStorySync
  module Audible
    class Client
      class NotAuthenticatedError < StandardError; end

      US_DOMAIN = "com"

      def initialize(auth:)
        @auth = auth
        @api_url = "https://api.audible.#{US_DOMAIN}"
      end

      def get_user_profile
        raise NotAuthenticatedError unless @auth.access_token
        response = HTTParty.get("#{@api_url}/user/profile", headers: headers)
        unless response.code == 200
          raise "Error getting user profile (#{response.code}):\n#{response.body}"
        end
        JSON.parse(response.body)
      end

      def get_library
        raise NotAuthenticatedError unless @auth.access_token
        response = HTTParty.get("#{api_url}/1.0/library", headers: headers)
        unless response.code == 200
          raise "Error getting library (#{response.code}):\n#{response.body}"
        end
        JSON.parse(response.body)
      end

      private

      def headers
        { "Authorization" => "Bearer #{@auth.access_token}" }
      end
    end
  end
end

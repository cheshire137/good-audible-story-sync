# frozen_string_literal: true
# typed: true

require "httparty"

module GoodAudibleStorySync
  module Audible
    class Client
      extend T::Sig

      class NotAuthenticatedError < StandardError; end

      US_DOMAIN = "com"

      sig { params(auth: Auth).void }
      def initialize(auth:)
        @auth = auth
        @api_url = "https://api.audible.#{US_DOMAIN}"
      end

      sig { returns(Hash) }
      def get_user_profile
        raise NotAuthenticatedError unless @auth.access_token
        response = HTTParty.get("#{@api_url}/user/profile", headers: headers)
        unless response.code == 200
          raise "Error getting user profile (#{response.code}):\n#{response.body}"
        end
        JSON.parse(response.body)
      end

      sig { returns T.untyped }
      def get_library
        raise NotAuthenticatedError unless @auth.access_token
        response = HTTParty.get("#{@api_url}/1.0/library", headers: headers)
        unless response.code == 200
          raise "Error getting library (#{response.code}):\n#{response.body}"
        end
        JSON.parse(response.body)
      end

      private

      sig { returns(T::Hash[String, String]) }
      def headers
        { "Authorization" => "Bearer #{@auth.access_token}" }
      end
    end
  end
end

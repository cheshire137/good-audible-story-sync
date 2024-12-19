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
        @have_attempted_token_refresh = false
      end

      sig { returns(Hash) }
      def get_user_profile
        raise NotAuthenticatedError unless @auth.access_token

        make_request = -> { HTTParty.get("#{@api_url}/user/profile", headers: headers) }
        make_json_request(make_request, action: "get user profile")
      end

      sig { returns T.untyped }
      def get_library
        raise NotAuthenticatedError unless @auth.access_token

        make_request = -> { HTTParty.get("#{@api_url}/1.0/library", headers: headers) }
        make_json_request(make_request, action: "get library")
      end

      private

      sig do
        params(make_request: T.proc.returns(HTTParty::Response), action: String).returns(T.untyped)
      end
      def make_json_request(make_request, action:)
        response = make_request.call
        handle_json_response(action: action, response: response)
      rescue Auth::InvalidTokenError
        if @have_attempted_token_refresh
          puts "Invalid token persists after refreshing it, giving up"
        else
          refresh_token
        end
        response = make_request.call
        handle_json_response(action: action, response: response)
      end

      sig { params(action: String, response: HTTParty::Response).returns(T.untyped) }
      def handle_json_response(action:, response:)
        Auth.handle_http_error(action: action, response: response) unless response.code == 200
        JSON.parse(response.body)
      end

      sig { returns(T::Hash[String, String]) }
      def headers
        { "Authorization" => "Bearer #{@auth.access_token}" }
      end

      sig { void }
      def refresh_token
        puts "Refreshing Audible access token..."
        new_access_token, new_expires = Auth.refresh_token(@auth.refresh_token)
        @auth.access_token = new_access_token
        @auth.expires = new_expires
        @have_attempted_token_refresh = true
      end
    end
  end
end

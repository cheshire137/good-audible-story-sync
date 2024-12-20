# frozen_string_literal: true
# typed: true

require "httparty"

module GoodAudibleStorySync
  module Audible
    class Client
      extend T::Sig

      class NotAuthenticatedError < StandardError; end

      US_DOMAIN = "com"

      sig { params(auth: Auth, options: Options).void }
      def initialize(auth:, options:)
        @auth = auth
        @api_url = "https://api.audible.#{US_DOMAIN}"
        @have_attempted_token_refresh = false
        @options = options
      end

      sig { returns(UserProfile) }
      def get_user_profile
        raise NotAuthenticatedError unless @auth.access_token

        url = "#{@api_url}/user/profile"
        puts "GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        data = make_json_request(make_request, action: "get user profile")
        UserProfile.new(data)
      end

      # https://audible.readthedocs.io/en/master/misc/external_api.html#library
      sig { params(page: Integer, per_page: Integer).returns([Integer, T::Array[LibraryItem]]) }
      def get_library_page(page: 1, per_page: 50)
        raise NotAuthenticatedError unless @auth.access_token

        params = {
          "sort_by" => "-PurchaseDate",
          "include_pending" => "false",
          "num_results" => per_page,
          "page" => page,
          "response_groups" => "contributors,is_finished,listening_status,percent_complete,product_desc",
        }
        url = "#{@api_url}/1.0/library?#{URI.encode_www_form(params)}"
        puts "GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        total_count = T.let(0, Integer)
        process_headers = ->(headers) { total_count = headers["total-count"].to_i }
        library_data = make_json_request(make_request, action: "get library",
          process_headers: process_headers)
        page_items = library_data["items"].map { |data| LibraryItem.new(data) }
        [total_count, page_items]
      end

      sig { returns T::Array[LibraryItem] }
      def get_all_library_pages
        per_page = 999
        result = T.let([], T::Array[LibraryItem])
        total_count, page_items = get_library_page(page: 1, per_page: per_page)
        puts "\tLoaded #{page_items.size} of #{total_count} item(s) in library"
        result.concat(page_items)
        total_pages = (total_count.to_f / per_page).ceil
        (2..total_pages).each do |page|
          _, page_items = get_library_page(page: page, per_page: per_page)
          puts "\tLoaded #{result.size + page_items.size} of #{total_count} item(s) in library"
          result.concat(page_items)
        end
        result
      end

      private

      sig do
        params(
          make_request: T.proc.returns(HTTParty::Response),
          action: String,
          process_headers: T.nilable(T.proc.params(arg0: Hash).void),
        ).returns(T.untyped)
      end
      def make_json_request(make_request, action:, process_headers: nil)
        response = make_request.call
        process_headers&.call(response.headers)
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
        @auth.save_to_file(@options.credentials_file)
        @have_attempted_token_refresh = true
      end
    end
  end
end

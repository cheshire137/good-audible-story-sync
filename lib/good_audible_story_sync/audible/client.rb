# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "date"
require "httparty"

module GoodAudibleStorySync
  module Audible
    class Client
      extend T::Sig

      class NotAuthenticatedError < StandardError; end

      US_DOMAIN = "com"

      sig { params(auth: Auth, options: Options, credentials_db: Database::Credentials).void }
      def initialize(auth:, options:, credentials_db:)
        @auth = auth
        @api_url = "https://api.audible.#{US_DOMAIN}"
        @have_attempted_token_refresh = T.let(false, T::Boolean)
        @credentials_db = credentials_db
        @options = options
      end

      sig { returns(UserProfile) }
      def get_user_profile
        raise NotAuthenticatedError unless @auth.access_token

        url = "#{@api_url}/user/profile"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        data = make_json_request(make_request, action: "get user profile")
        UserProfile.new(data)
      end

      # https://audible.readthedocs.io/en/master/misc/external_api.html#get--1.0-stats-status-finished
      sig { returns T::Hash[String, DateTime] }
      def get_finish_times_by_asin
        raise NotAuthenticatedError unless @auth.access_token

        url = "#{@api_url}/1.0/stats/status/finished"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        data = make_json_request(make_request, action: "get finish times by ASIN")
        finished_items = (data["mark_as_finished_status_list"] || [])
          .select { |item| item["is_marked_as_finished"] }
        result = T.let({}, T::Hash[String, DateTime])
        finished_items.each do |item|
          asin = item["asin"]
          timestamp = DateTime.parse(item["event_timestamp"])
          if !result.key?(asin) || timestamp > result[asin]
            result[asin] = timestamp
          end
        end
        result
      end

      # https://audible.readthedocs.io/en/master/misc/external_api.html#get--1.0-stats-aggregates
      sig { returns Hash }
      def get_aggregate_stats
        raise NotAuthenticatedError unless @auth.access_token

        params = {
          "locale" => "en_US",
          "response_groups" => "total_listening_stats",
          "store" => "Audible",
        }
        url = "#{@api_url}/1.0/stats/aggregates?#{URI.encode_www_form(params)}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        make_json_request(make_request, action: "get aggregate stats")
      end

      # https://audible.readthedocs.io/en/master/misc/external_api.html#get--1.0-collections
      sig { returns Hash }
      def get_collections
        raise NotAuthenticatedError unless @auth.access_token

        url = "#{@api_url}/1.0/collections"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        make_json_request(make_request, action: "get collections")
      end

      # https://audible.readthedocs.io/en/master/misc/external_api.html#get--1.0-library-(string-asin)
      sig { params(asin: String).returns(LibraryItem) }
      def get_library_item(asin:)
        raise NotAuthenticatedError unless @auth.access_token

        params = {
          "response_groups" => "contributors,media,price,product_attrs,product_desc," \
            "product_details,product_extended_attrs,product_plan_details,product_plans," \
            "rating,sample,sku,series,reviews,ws4v,origin,relationships,review_attrs," \
            "categories,badge_types,category_ladders,claim_code_url,is_downloaded," \
            "is_finished,is_returnable,origin_asin,pdf_url,percent_complete,periodicals," \
            "provided_review",
        }
        url = "#{@api_url}/1.0/library/#{asin}?#{URI.encode_www_form(params)}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        data = make_json_request(make_request, action: "get library item #{asin}")
        LibraryItem.new(data["item"])
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
          "response_groups" => "contributors,is_finished,listening_status,percent_complete,product_desc,product_details",
        }
        url = "#{@api_url}/1.0/library?#{URI.encode_www_form(params)}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        make_request = -> { HTTParty.get(url, headers: headers) }
        total_count = T.let(0, Integer)
        process_headers = ->(headers) { total_count = headers["total-count"].to_i }
        library_data = make_json_request(make_request, action: "get library",
          process_headers: process_headers)
        page_items = library_data["items"].map { |data| LibraryItem.new(data) }
        [total_count, page_items]
      end

      sig { returns Library }
      def get_all_library_pages
        per_page = 999
        all_items = T.let([], T::Array[LibraryItem])
        total_count, page_items = get_library_page(page: 1, per_page: per_page)
        puts "#{Util::TAB}Loaded #{page_items.size} of #{total_count} item(s) in library"
        all_items.concat(page_items)
        total_pages = (total_count.to_f / per_page).ceil
        (2..total_pages).each do |page|
          _, page_items = get_library_page(page: page, per_page: per_page)
          puts "#{Util::TAB}Loaded #{all_items.size + page_items.size} of #{total_count} " \
            "item(s) in library"
          all_items.concat(page_items)
        end
        Library.new(items: all_items)
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
      rescue Auth::InvalidTokenError, Auth::ForbiddenError
        if @have_attempted_token_refresh
          puts "#{Util::ERROR_EMOJI} Invalid token persists after refreshing it, giving up"
          nil
        else
          refresh_token
          response = make_request.call
          process_headers&.call(response.headers)
          handle_json_response(action: action, response: response)
        end
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
        puts "#{Util::INFO_EMOJI} Refreshing Audible access token..."
        new_access_token, new_expires = Auth.refresh_token(@auth.refresh_token)
        @auth.access_token = new_access_token
        @auth.expires = new_expires
        @auth.save_to_database(@credentials_db)
        @have_attempted_token_refresh = true
      end
    end
  end
end

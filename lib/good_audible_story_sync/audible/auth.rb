# frozen_string_literal: true
# typed: true

require "base64"
require "digest"
require "httparty"
require "json"
require "securerandom"
require "uri"

module GoodAudibleStorySync
  module Audible
    class Auth
      extend T::Sig

      US_MARKETPLACE_ID = "AF2M0KC94RCEA"
      US_DOMAIN = "com"

      class InvalidTokenError < StandardError; end
      class ForbiddenError < StandardError; end

      sig { params(action: String, response: HTTParty::Response).void }
      def self.handle_http_error(action:, response:)
        code = response.code
        raise ForbiddenError if code == 403

        json = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          raise "Failed to #{action} (#{code}):\n#{response.body}"
        end

        error_type = json["error"]
        raise InvalidTokenError if error_type == "invalid_token"

        if error_type
          error_description = json["error_description"]
          raise "Failed to #{action} (#{code}): #{error_type} #{error_description}"
        end

        message = json["message"]
        if message
          raise "Failed to #{action} (#{code}): #{message}"
        end

        raise "Failed to #{action} (#{code}):\n#{response.body}"
      end

      sig { params(expires_s: Integer).returns(Time) }
      def self.expiration_time_from_seconds(expires_s)
        Time.now.utc + (expires_s/86400.0)
      end

      sig { params(source_token: String).returns([String, Time]) }
      def self.refresh_token(source_token)
        raise "No source token provided to refresh" if source_token.size < 1

        body = {
          "requested_token_type" => "access_token",
          "source_token_type" => "refresh_token",
          "app_name" => "Audible",
          "app_version" => "3.56.2",
          "source_token" => source_token,
        }
        url = "https://api.amazon.#{US_DOMAIN}/auth/token"
        puts "POST #{url}"
        response = HTTParty.post(url, body: body)
        handle_http_error(action: "refresh token", response: response) unless response.code == 200

        json = JSON.parse(response.body)
        expires_s = json["expires_in"].to_i
        expires = expiration_time_from_seconds(expires_s)
        access_token = json["access_token"]
        [access_token, expires]
      end

      attr_reader :adp_token, :device_private_key, :refresh_token, :website_cookies,
        :store_authentication_cookie, :device_info, :customer_info

      sig { returns T.nilable(String) }
      attr_accessor :access_token

      sig { returns T.nilable(Time) }
      attr_accessor :expires

      sig { void }
      def initialize
        verifier = SecureRandom.random_bytes(32)
        @code_verifier = Base64.urlsafe_encode64(verifier).delete_suffix("=")
        @device_serial = SecureRandom.uuid.upcase.delete('-')
        @client_id = "#{device_serial}#A2CZJZGLK2JJVM".unpack1('H*')
        @auth_code = nil
        @adp_token = nil
        @device_private_key = nil
        @access_token = nil
        @refresh_token = nil
        @expires = nil
        @website_cookies = nil
        @store_authentication_cookie = nil
        @device_info = nil
        @customer_info = nil
        @loaded_from_database = T.let(false, T::Boolean)
      end

      sig { returns String }
      def oauth_url
        m = Digest::SHA256.digest(code_verifier)
        s256_code_challenge = Base64.urlsafe_encode64(m).delete_suffix("=")
        base_url = "https://www.amazon.#{US_DOMAIN}/ap/signin"
        return_to = "https://www.amazon.#{US_DOMAIN}/ap/maplanding"
        assoc_handle = "amzn_audible_ios_us"
        page_id = "amzn_audible_ios"
        params = {
          "openid.oa2.response_type" => "code",
          "openid.oa2.code_challenge_method" => "S256",
          "openid.oa2.code_challenge" => s256_code_challenge,
          "openid.return_to" => return_to,
          "openid.assoc_handle" => assoc_handle,
          "openid.identity" => "http://specs.openid.net/auth/2.0/identifier_select",
          "pageId" => page_id,
          "accountStatusPolicy" => "P1",
          "openid.claimed_id" => "http://specs.openid.net/auth/2.0/identifier_select",
          "openid.mode" => "checkid_setup",
          "openid.ns.oa2" => "http://www.amazon.com/ap/ext/oauth/2",
          "openid.oa2.client_id" => "device:#{client_id}",
          "openid.ns.pape" => "http://specs.openid.net/extensions/pape/1.0",
          "marketPlaceId" => US_MARKETPLACE_ID,
          "openid.oa2.scope" => "device_auth_access",
          "forceMobileLayout" => "true",
          "openid.ns" => "http://specs.openid.net/auth/2.0",
          "openid.pape.max_auth_age" => "0",
        }
        "#{base_url}?#{URI.encode_www_form(params)}"
      end

      sig { params(url: String).void }
      def set_authorization_code_from_oauth_redirect_url(url)
        uri = URI.parse(url)
        query = uri.query
        if query
          redirect_params = URI.decode_www_form(query).to_h
          @auth_code = redirect_params["openid.oa2.authorization_code"]
        end
      end

      sig { returns T::Boolean }
      def register_device
        raise "No authorization code has been set" if auth_code.nil? || auth_code.size < 1

        body = {
          "requested_token_type" => ["bearer", "mac_dms", "website_cookies",
            "store_authentication_cookie"],
          "cookies" => {"website_cookies" => [], "domain" => ".amazon.#{US_DOMAIN}"},
          "registration_data" => {
            "domain" => "Device",
            "app_version" => "3.56.2",
            "device_serial" => device_serial,
            "device_type" => "A2CZJZGLK2JJVM",
            "device_name" => "GoodAudibleStorySync",
            "os_version" => "15.0.0",
            "software_version" => "35602678",
            "device_model" => "iPhone",
            "app_name" => "Audible",
          },
          "auth_data" => {
            "client_id" => client_id,
            "authorization_code" => auth_code,
            "code_verifier" => code_verifier,
            "code_algorithm" => "SHA-256",
            "client_domain" => "DeviceLegacy",
          },
          "requested_extensions" => ["device_info", "customer_info"],
        }

        url = "https://api.amazon.#{US_DOMAIN}/auth/register"
        puts "POST #{url}"
        response = HTTParty.post(url, body: body.to_json)
        unless response.code == 200
          self.class.handle_http_error(action: "register device", response: response)
        end

        resp_json = JSON.parse(response.body)
        success_data = resp_json.dig("response", "success")
        raise "Failed to register device:\n#{response.body}" unless success_data

        tokens = success_data["tokens"]
        @adp_token = tokens.dig("mac_dms", "adp_token")
        @device_private_key = tokens.dig("mac_dms", "device_private_key")
        @store_authentication_cookie = tokens["store_authentication_cookie"]
        @access_token = tokens.dig("bearer", "access_token")
        @refresh_token = tokens.dig("bearer", "refresh_token")
        expires_s = tokens.dig("bearer", "expires_in").to_i
        @expires = self.class.expiration_time_from_seconds(expires_s)

        extensions = success_data["extensions"]
        @device_info = extensions["device_info"]
        @customer_info = extensions["customer_info"]

        @website_cookies = {}
        tokens["website_cookies"].each do |cookie|
          value = cookie["Value"]
          @website_cookies[cookie["Name"]] = if value
            value.gsub('"', '')
          end
        end

        !@access_token.nil? && !@access_token.strip.empty?
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        {
          "audible" => {
            "adp_token" => adp_token,
            "device_private_key" => device_private_key,
            "access_token" => access_token,
            "refresh_token" => refresh_token,
            "expires" => expires,
            "website_cookies" => website_cookies,
            "store_authentication_cookie" => store_authentication_cookie,
            "device_info" => device_info,
            "customer_info" => customer_info,
          },
        }
      end

      sig { params(cred_client: Database::Credentials).void }
      def save_to_database(cred_client)
        cred_client.upsert(key: "audible", value: to_h)
      end

      sig { returns T::Boolean }
      def loaded_from_database?
        @loaded_from_database
      end

      sig { params(cred_client: Database::Credentials).returns(T::Boolean) }
      def load_from_database(cred_client)
        audible_data = cred_client.find(key: "audible")
        unless audible_data
          puts "#{Util::INFO_EMOJI} No Audible credentials found in database"
          return false
        end

        @adp_token = audible_data["adp_token"]
        @device_private_key = audible_data["device_private_key"]
        @access_token = audible_data["access_token"]
        @refresh_token = audible_data["refresh_token"]
        @expires = audible_data["expires"]
        @website_cookies = audible_data["website_cookies"]
        @store_authentication_cookie = audible_data["store_authentication_cookie"]
        @device_info = audible_data["device_info"]
        @customer_info = audible_data["customer_info"]

        @loaded_from_database = !!(!@access_token.nil? && !@access_token.strip.empty?)
      end

      private

      attr_reader :code_verifier, :device_serial, :client_id, :auth_code
    end
  end
end

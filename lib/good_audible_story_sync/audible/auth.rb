# frozen_string_literal: true

require "base64"
require "digest"
require "httparty"
require "json"
require "securerandom"
require "uri"

module GoodAudibleStorySync
  module Audible
    class Auth
      US_MARKETPLACE_ID = "AF2M0KC94RCEA"
      US_DOMAIN = "com"

      def initialize
        verifier = SecureRandom.random_bytes(32)
        @code_verifier = Base64.urlsafe_encode64(verifier).delete_suffix("=")
        @device_serial = SecureRandom.uuid.upcase.delete('-')
        @client_id = "#{device_serial}#A2CZJZGLK2JJVM".unpack1('H*')
        @auth_code = nil
      end

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

      def set_authorization_code_from_oauth_redirect_url(url)
        uri = URI.parse(url)
        redirect_params = URI.decode_www_form(uri.query).to_h
        @auth_code = redirect_params["openid.oa2.authorization_code"]
      end

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
            "device_name" => "%FIRST_NAME%%FIRST_NAME_POSSESSIVE_STRING%%DUPE_STRATEGY_1ST%Audible for iPhone",
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
        response = HTTParty.post("https://api.amazon.#{US_DOMAIN}/auth/register",
          body: body.to_json)
        unless response.code == 200
          raise "Failed to register device: (HTTP #{response.code})\n#{response.body}"
        end

        resp_json = JSON.parse(response.body)
        success_data = resp_json["response"]["success"]
        raise "Failed to register device:\n#{response.body}" unless success_data

        tokens = success_data["tokens"]
        adp_token = tokens["mac_dms"]["adp_token"]
        device_private_key = tokens["mac_dms"]["device_private_key"]
        store_authentication_cookie = tokens["store_authentication_cookie"]
        access_token = tokens["bearer"]["access_token"]
        refresh_token = tokens["bearer"]["refresh_token"]
        expires_s = tokens["bearer"]["expires_in"].to_i
        expires = Time.now.utc + (expires_s/86400.0)
        extensions = success_data["extensions"]
        device_info = extensions["device_info"]
        customer_info = extensions["customer_info"]
        website_cookies = {}
        tokens["website_cookies"].each do |cookie|
          website_cookies[cookie["Name"]] = cookie["Value"].gsub('"', '')
        end

        {
          "adp_token" => adp_token,
          "device_private_key" => device_private_key,
          "access_token" => access_token,
          "refresh_token" => refresh_token,
          "expires" => expires,
          "website_cookies" => website_cookies,
          "store_authentication_cookie" => store_authentication_cookie,
          "device_info" => device_info,
          "customer_info" => customer_info,
        }
      end

      private

      attr_reader :code_verifier, :device_serial, :client_id, :auth_code
    end
  end
end

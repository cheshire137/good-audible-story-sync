# frozen_string_literal: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      def self.call
        audible_auth = Auth.new
        puts "Please authenticate with Audible via: #{audible_auth.oauth_url}"
        puts "\nEnter the URL you were redirected to after logging in:"
        url_after_login = gets.chomp
        audible_auth.set_authorization_code_from_oauth_redirect_url(url_after_login)

        puts "\nRegistering Audible device..."
        success = begin
          audible_auth.register_device
        rescue => err
          puts "Error registering device: #{err}"
          return
        end

        unless success
          puts "\nFailed to authenticate with Audible"
          return
        end

        device_name = audible_auth.device_info["device_name"]
        puts "\nSuccessfully authenticated with Audible and registered device: #{device_name}"
        audible_auth
      end
    end
  end
end

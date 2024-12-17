# frozen_string_literal: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      def self.call
        audible_auth = Auth.new
        puts "Audible auth URL: #{audible_auth.oauth_url}"
        puts "\n\nEnter the URL you were redirected to after logging in:"
        url_after_login = gets.chomp
        audible_auth.set_authorization_code_from_oauth_redirect_url(url_after_login)
        puts "\n\nRegistering Audible device..."
        device_info = audible_auth.register_device
      end
    end
  end
end

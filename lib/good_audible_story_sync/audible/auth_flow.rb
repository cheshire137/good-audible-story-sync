# frozen_string_literal: true
# typed: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      extend T::Sig

      sig { params(credentials_file: Util::EncryptedJsonFile).returns(T.nilable(Auth)) }
      def self.run(credentials_file:)
        new(credentials_file: credentials_file).run
      end

      sig { params(credentials_file: Util::EncryptedJsonFile).void }
      def initialize(credentials_file:)
        @audible_auth = Auth.new
        @credentials_file = credentials_file
      end

      sig { returns T.nilable(Auth) }
      def run
        success = credentials_file.exists? ? load_from_file : log_in_via_oauth
        success ? audible_auth : nil
      end

      private

      sig { returns Auth }
      attr_reader :audible_auth

      sig { returns Util::EncryptedJsonFile }
      attr_reader :credentials_file

      sig { returns T::Boolean }
      def load_from_file
        puts "Found existing GoodAudibleStorySync credential file #{credentials_file}, loading..."
        audible_auth.load_from_file(credentials_file)
      end

      sig { returns T::Boolean }
      def log_in_via_oauth
        puts "GoodAudibleStorySync credential file #{credentials_file} does not yet exist"
        puts "Please authenticate with Audible via: #{audible_auth.oauth_url}"
        puts "\nEnter the URL you were redirected to after logging in:"
        url_after_login = gets.chomp
        audible_auth.set_authorization_code_from_oauth_redirect_url(url_after_login)

        puts "\nRegistering Audible device..."
        success = begin
          audible_auth.register_device
        rescue => err
          puts "Error registering device: #{err}"
          return false
        end

        unless success
          puts "\nFailed to authenticate with Audible"
          return false
        end

        device_name = audible_auth.device_info["device_name"]
        puts "\nSuccessfully authenticated with Audible and registered device: #{device_name}"

        puts "Saving Audible credentials to #{credentials_file}..."
        audible_auth.save_to_file(credentials_file)
      end
    end
  end
end

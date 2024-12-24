# frozen_string_literal: true
# typed: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      extend T::Sig

      sig { params(db_client: Database::Client).returns(T.nilable(Auth)) }
      def self.run(db_client:)
        new(db_client: db_client).run
      end

      sig { params(db_client: Database::Client).void }
      def initialize(db_client:)
        @audible_auth = Auth.new
        @credentials_db = db_client.credentials
      end

      sig { returns T.nilable(Auth) }
      def run
        success = load_from_database || log_in_via_oauth
        success ? audible_auth : nil
      end

      private

      sig { returns Auth }
      attr_reader :audible_auth

      sig { returns T::Boolean }
      def load_from_database
        puts "#{Util::INFO_EMOJI} Looking for saved Audible credentials in database..."
        success = audible_auth.load_from_database(@credentials_db)
        puts "#{Util::SUCCESS_EMOJI} Found saved Audible credentials." if success
        success
      end

      sig { returns T::Boolean }
      def log_in_via_oauth
        puts "Please authenticate with Audible via: #{audible_auth.oauth_url}"
        puts "\nEnter the URL you were redirected to after logging in:"
        url_after_login = gets.chomp
        audible_auth.set_authorization_code_from_oauth_redirect_url(url_after_login)

        puts "\n#{Util::INFO_EMOJI} Registering Audible device..."
        success = begin
          audible_auth.register_device
        rescue => err
          puts "#{Util::ERROR_EMOJI} Error registering device: #{err}"
          return false
        end

        unless success
          puts "\n#{Util::ERROR_EMOJI} Failed to authenticate with Audible"
          return false
        end

        device_name = audible_auth.device_info["device_name"]
        puts "\n#{Util::SUCCESS_EMOJI} Successfully authenticated with Audible and " \
          "registered device: #{device_name}"

        audible_auth.save_to_database(@credentials_db)
        true
      end
    end
  end
end

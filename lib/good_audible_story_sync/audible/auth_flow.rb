# frozen_string_literal: true
# typed: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      extend T::Sig

      sig do
        params(
          credentials_file: Util::EncryptedJsonFile,
          db_client: Database::Client
        ).returns(T.nilable(Auth))
      end
      def self.run(credentials_file:, db_client:)
        new(credentials_file: credentials_file, db_client: db_client).run
      end

      sig do
        params(credentials_file: Util::EncryptedJsonFile, db_client: Database::Client).void
      end
      def initialize(credentials_file:, db_client:)
        @audible_auth = Auth.new
        @credentials_file = credentials_file
        @credentials_db = Database::Credentials.new(db_client: db_client)
      end

      sig { returns T.nilable(Auth) }
      def run
        success = load_from_database || (credentials_file.exists? ? load_from_file : log_in_via_oauth)
        success ? audible_auth : nil
      end

      private

      sig { returns Auth }
      attr_reader :audible_auth

      sig { returns Util::EncryptedJsonFile }
      attr_reader :credentials_file

      sig { returns T::Boolean }
      def load_from_database
        puts "#{Util::INFO_EMOJI} Looking for saved Audible credentials in database..."
        success = audible_auth.load_from_database(@credentials_db)
        puts "#{Util::SUCCESS_EMOJI} Found saved Audible credentials." if success
        success
      end

      sig { returns T::Boolean }
      def load_from_file
        puts "#{Util::INFO_EMOJI} Found existing GoodAudibleStorySync credential " \
          "file #{credentials_file}, loading..."
        success = audible_auth.load_from_file(credentials_file)
        audible_auth.save_to_database(@credentials_db) if success
        success
      end

      sig { returns T::Boolean }
      def log_in_via_oauth
        puts "#{Util::INFO_EMOJI} GoodAudibleStorySync credential file #{credentials_file} " \
          "does not yet exist"
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

        puts "#{Util::SAVE_EMOJI} Saving Audible credentials to #{credentials_file}..."
        audible_auth.save_to_file(credentials_file)
      end
    end
  end
end

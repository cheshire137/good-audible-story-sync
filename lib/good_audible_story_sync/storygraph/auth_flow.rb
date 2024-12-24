# frozen_string_literal: true
# typed: true

require "io/console"

module GoodAudibleStorySync
  module Storygraph
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

      sig { params(credentials_file: Util::EncryptedJsonFile, db_client: Database::Client).void }
      def initialize(credentials_file:, db_client:)
        @credentials_file = credentials_file
        @credentials_db = db_client.credentials
      end

      sig { returns T.nilable(Auth) }
      def run
        auth_from_db = load_from_database
        return auth_from_db if auth_from_db

        can_load_from_file? ? load_from_file : log_in_via_website
      rescue Auth::AuthError
        puts "Failed to sign in to Storygraph."
        nil
      end

      private

      sig { returns T.nilable(Auth) }
      def load_from_database
        auth = Auth.new
        puts "#{Util::INFO_EMOJI} Looking for saved Storygraph credentials in database..."
        success = auth.load_from_database(@credentials_db)
        puts "#{Util::SUCCESS_EMOJI} Found saved Storygraph credentials." if success
        return nil unless success

        begin
          auth.sign_in
        rescue Auth::AuthError => err
          puts "#{Util::ERROR_EMOJI} Failed to sign in to Storygraph: #{err.message}"
          return nil
        end

        auth
      end

      sig { returns T::Boolean }
      def can_load_from_file?
        return false unless @credentials_file.exists?
        @credentials_file.load.key?("storygraph")
      end

      sig { returns T.nilable(Auth) }
      def load_from_file
        puts "#{Util::INFO_EMOJI} Found existing GoodAudibleStorySync credential " \
          "file #{@credentials_file}, loading..."

        auth = Auth.new
        unless auth.load_from_file(@credentials_file)
          puts "#{Util::ERROR_EMOJI} Failed to load Storygraph credentials from #{@credentials_file}"
          return nil
        end

        begin
          auth.sign_in
        rescue Auth::AuthError => err
          puts "#{Util::ERROR_EMOJI} Failed to sign in to Storygraph: #{err.message}"
          return nil
        end

        puts "Restored auth with Storygraph as #{auth.username}"
        auth.save_to_database(@credentials_db)
        auth
      end

      sig { returns T.nilable(Auth) }
      def log_in_via_website
        print "Enter Storygraph email: "
        email = gets.chomp
        print "Enter Storygraph password: "
        password = T.unsafe(STDIN).noecho(&:gets).chomp
        print "\n"

        auth = begin
          Auth.sign_in(email: email, password: password)
        rescue Auth::AuthError => err
          puts "#{Util::ERROR_EMOJI} Failed to sign in to Storygraph: #{err.message}"
          return nil
        end

        puts "Saving Storygraph credentials to #{@credentials_file}..."
        unless auth.save_to_file(@credentials_file)
          puts "#{Util::ERROR_EMOJI} Failed to save Storybook credentials to #{@credentials_file}"
        end

        auth
      end
    end
  end
end

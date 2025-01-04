# frozen_string_literal: true
# typed: true

require "io/console"

module GoodAudibleStorySync
  module Goodreads
    class AuthFlow
      extend T::Sig

      sig { params(credentials_db: Database::Credentials).returns(T.nilable(Auth)) }
      def self.run(credentials_db:)
        new(credentials_db: credentials_db).run
      end

      sig { params(credentials_db: Database::Credentials).void }
      def initialize(credentials_db:)
        @credentials_db = credentials_db
      end

      sig { returns T.nilable(Auth) }
      def run
        load_from_database || log_in_via_website
      rescue Auth::AuthError
        puts "Failed to sign in to Goodreads."
        nil
      end

      private

      sig { returns T.nilable(Auth) }
      def load_from_database
        auth = Auth.new
        puts "#{Util::INFO_EMOJI} Looking for saved Goodreads credentials in database..."
        success = auth.load_from_database(@credentials_db)
        puts "#{Util::SUCCESS_EMOJI} Found saved Goodreads credentials." if success
        return nil unless success

        begin
          auth.sign_in
        rescue Auth::AuthError => err
          puts "#{Util::ERROR_EMOJI} Failed to sign in to Goodreads: #{err.message}"
          return nil
        end

        auth
      end

      sig { returns T.nilable(Auth) }
      def log_in_via_website
        puts "#{Util::INFO_EMOJI} Logging in to Goodreads..."
        print "Enter Goodreads email: "
        email = gets.chomp
        print "Enter Goodreads password: "
        password = T.unsafe(STDIN).noecho(&:gets).chomp
        print "\n"

        auth = begin
          Auth.sign_in(email: email, password: password)
        rescue Auth::AuthError => err
          puts "#{Util::ERROR_EMOJI} Failed to sign in to Goodreads: #{err.message}"
          return nil
        end

        auth.save_to_database(@credentials_db)
        auth
      end
    end
  end
end

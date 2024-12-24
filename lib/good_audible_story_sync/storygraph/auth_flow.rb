# frozen_string_literal: true
# typed: true

require "io/console"

module GoodAudibleStorySync
  module Storygraph
    class AuthFlow
      extend T::Sig

      sig { params(db_client: Database::Client).returns(T.nilable(Auth)) }
      def self.run(db_client:)
        new(db_client: db_client).run
      end

      sig { params(db_client: Database::Client).void }
      def initialize(db_client:)
        @credentials_db = db_client.credentials
      end

      sig { returns T.nilable(Auth) }
      def run
        load_from_database || log_in_via_website
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

        auth.save_to_database(@credentials_db)
        auth
      end
    end
  end
end

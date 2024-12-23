# frozen_string_literal: true
# typed: true

require "io/console"

module GoodAudibleStorySync
  module Storygraph
    class AuthFlow
      extend T::Sig

      sig { params(credentials_file: Util::EncryptedJsonFile).returns(T.nilable(Auth)) }
      def self.run(credentials_file:)
        new(credentials_file: credentials_file).run
      end

      sig { params(credentials_file: Util::EncryptedJsonFile).void }
      def initialize(credentials_file:)
        @credentials_file = credentials_file
      end

      sig { returns T.nilable(Auth) }
      def run
        if @credentials_file.exists? && @credentials_file.load["storygraph"]
          load_from_file
        else
          log_in_via_website
        end
      rescue Auth::AuthError
        puts "Failed to sign in to Storygraph."
        nil
      end

      private

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

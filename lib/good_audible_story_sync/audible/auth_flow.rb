# frozen_string_literal: true
# typed: true

require "uri"

module GoodAudibleStorySync
  module Audible
    class AuthFlow
      extend T::Sig

      sig { params(output_file: String).returns(T.nilable(Auth)) }
      def self.run(output_file:)
        audible_auth = Auth.new

        if File.exist?(output_file)
          puts "Found existing GoodAudibleStorySync credential file #{output_file}, loading..."
          audible_auth.load_from_file(output_file)
        else
          puts "GoodAudibleStorySync credential file #{output_file} does not yet exist"
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

          puts "Saving auth credentials to #{output_file}..."
          audible_auth.save_to_file(output_file)
        end

        audible_auth
      end
    end
  end
end

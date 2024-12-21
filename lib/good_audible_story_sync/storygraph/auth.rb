# frozen_string_literal: true
# typed: true

require "mechanize"
require_relative "../util/encrypted_file"

module GoodAudibleStorySync
  module Storygraph
    class Auth
      extend T::Sig

      class AuthError < StandardError; end

      sig { returns T.nilable(String) }
      attr_reader :email, :username

      sig { void }
      def initialize
        @agent = Mechanize.new
        @email = T.let(nil, T.nilable(String))
        @password = T.let(nil, T.nilable(String))
        @username = T.let(nil, T.nilable(String))
        @loaded_from_file = T.let(false, T::Boolean)
      end

      sig { params(email: String, password: String).void }
      def login(email:, password:)
        puts "Signing into Storygraph as #{email}..."
        page = @agent.get("https://app.thestorygraph.com/users/sign_in")
        sign_in_form = page.form_with(action: "/users/sign_in") do |form|
          form["user[email]"] = email
          form["user[password]"] = password
        end
        page_after_sign_in = sign_in_form.submit
        profile_link = page_after_sign_in.link_with(text: "Profile")
        successful_sign_in = !profile_link.nil?
        raise AuthError unless successful_sign_in

        @email = email
        @password = password
        @username = profile_link.href.split("/profile/").last
        puts "Successfully signed in to Storygraph as #{@username}"
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        {
          "storygraph" => {
            "email" => @email,
            "password" => @password,
            "username" => @username,
          },
        }
      end

      sig { params(encrypted_file: Util::EncryptedJsonFile).returns(T::Boolean) }
      def save_to_file(encrypted_file)
        bytes_written = encrypted_file.merge(to_h)
        bytes_written > 0
      end

      sig { params(encrypted_file: Util::EncryptedJsonFile).returns(T::Boolean) }
      def load_from_file(encrypted_file)
        return false unless encrypted_file.exists?

        data = encrypted_file.load

        storygraph_data = data["storygraph"]
        @email = storygraph_data["email"]
        @password = storygraph_data["password"]
        @username = storygraph_data["username"]

        @loaded_from_file = true
      end
    end
  end
end

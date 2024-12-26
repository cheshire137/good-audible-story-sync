# frozen_string_literal: true
# typed: true

require "mechanize"

module GoodAudibleStorySync
  module Storygraph
    class Auth
      extend T::Sig

      BASE_URL = "https://app.thestorygraph.com"

      class AuthError < StandardError; end

      sig { params(email: String, password: String).returns(Auth) }
      def self.sign_in(email:, password:)
        auth = new(data: { "email" => email, "password" => password })
        auth.sign_in
        auth
      end

      sig { params(page: Mechanize::Page).returns(T::Boolean) }
      def self.sign_in_page?(page)
        page.uri.to_s.end_with?("/users/sign_in")
      end

      sig { returns T.nilable(String) }
      attr_reader :email, :username

      sig { returns Mechanize }
      attr_reader :agent

      sig { params(agent: T.nilable(Mechanize), data: T::Hash[String, T.nilable(String)]).void }
      def initialize(agent: nil, data: {})
        @agent = agent || Mechanize.new
        @email = data["email"]
        @password = data["password"]
        @username = data["username"]
      end

      sig { void }
      def sign_in
        raise AuthError.new("Cannot sign in without credentials") if @email.nil? || @password.nil?

        puts "#{Util::INFO_EMOJI} Signing into Storygraph as #{@email}..."
        page = @agent.get("#{BASE_URL}/users/sign_in")
        sign_in_form = page.form_with(action: "/users/sign_in") do |form|
          form["user[email]"] = @email
          form["user[password]"] = @password
        end
        page_after_sign_in = sign_in_form.submit
        profile_link = page_after_sign_in.link_with(text: "Profile")
        successful_sign_in = !profile_link.nil? && !self.class.sign_in_page?(page_after_sign_in)
        raise AuthError.new("Invalid credentials") unless successful_sign_in

        @username = profile_link.href.split("/profile/").last
        puts "#{Util::INFO_EMOJI} Successfully signed in to Storygraph as #{username}"
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        { "email" => @email, "password" => @password, "username" => @username }
      end

      sig { params(cred_client: Database::Credentials).void }
      def save_to_database(cred_client)
        cred_client.upsert(key: "storygraph", value: to_h)
      end

      sig { params(cred_client: Database::Credentials).returns(T::Boolean) }
      def load_from_database(cred_client)
        storygraph_data = cred_client.find(key: "storygraph")
        unless storygraph_data
          puts "#{Util::INFO_EMOJI} No Storygraph credentials found in database"
          return false
        end

        @email = storygraph_data["email"]
        @password = storygraph_data["password"]
        @username = storygraph_data["username"]

        true
      end
    end
  end
end

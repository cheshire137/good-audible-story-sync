# frozen_string_literal: true
# typed: true

require "mechanize"

module GoodAudibleStorySync
  module Goodreads
    class Auth
      extend T::Sig

      class Error < StandardError; end

      BASE_URL = "https://www.goodreads.com"
      CREDENTIALS_DB_KEY = "goodreads"

      sig { params(email: String, password: String).returns(Auth) }
      def self.sign_in(email:, password:)
        auth = new(data: { "email" => email, "password" => password })
        auth.sign_in
        auth
      end

      sig { params(page: Mechanize::Page).returns(T::Boolean) }
      def self.sign_in_page?(page)
        url = page.uri.to_s
        url.end_with?("/user/sign_in") || url.end_with?("/ap/signin")
      end

      sig { returns T.nilable(String) }
      attr_reader :email, :profile_name, :user_id, :slug

      sig { returns Mechanize }
      attr_reader :agent

      sig { params(agent: T.nilable(Mechanize), data: T::Hash[String, T.nilable(String)]).void }
      def initialize(agent: nil, data: {})
        @agent = agent || Mechanize.new
        @agent.user_agent_alias = "iPad"
        @email = T.let(data["email"], T.nilable(String))
        @password = T.let(data["password"], T.nilable(String))
        @profile_name = T.let(data["profile_name"], T.nilable(String))
        @user_id = T.let(data["user_id"], T.nilable(String))
        @slug = T.let(data["slug"], T.nilable(String))
      end

      sig { returns(T.untyped) }
      def sign_in
        raise Error.new("Cannot sign in without credentials") if @email.nil? || @password.nil?

        puts "#{Util::INFO_EMOJI} Signing into Goodreads as #{@email}..."
        select_sign_in_page = begin
          get("/user/sign_in")
        rescue Errno::ETIMEDOUT => err
          raise Error.new("Failed to load Goodreads: #{err}")
        end

        email_sign_in_link = T.let(select_sign_in_page.link_with(text: /Sign in with email/),
          T.nilable(Mechanize::Page::Link))
        raise Error.new("Failed to find sign-in link on #{select_sign_in_page.uri}") unless email_sign_in_link

        email_sign_in_page = email_sign_in_link.click
        sign_in_form = T.let(email_sign_in_page.form_with(name: "signIn"), T.nilable(Mechanize::Form))
        raise Error.new("Could not find sign-in form on #{email_sign_in_page.uri}") unless sign_in_form

        email_field = sign_in_form.field_with(name: "email")
        raise Error.new("Could not find email field in sign-in form") unless email_field
        password_field = sign_in_form.field_with(name: "password")
        raise Error.new("Could not find password field in sign-in form") unless password_field

        email_field.value = @email
        password_field.value = @password
        page_after_sign_in = begin
          sign_in_form.submit
        rescue Mechanize::ResponseCodeError => err
          raise Error.new("Error signing into Goodreads: #{err}")
        end

        cookieless_message_el = page_after_sign_in.at("#ap_error_page_cookieless_message")
        if cookieless_message_el
          raise Error.new("Could not sign in to Goodreads without cookies: " \
            "#{Util.squish(cookieless_message_el.text)}")
        end

        profile_link = T.let(page_after_sign_in.link_with(text: "Profile"), T.nilable(Mechanize::Page::Link))
        successful_sign_in = !profile_link.nil? && !self.class.sign_in_page?(page_after_sign_in)
        raise Error.new("Could not log in to Goodreads") unless successful_sign_in

        profile_page = profile_link.click
        profile_header = profile_page.at("h1")
        @profile_name = if profile_header
          profile_header.text.strip.split(/\n/).first
        end
        user_id_and_slug = profile_page.uri.path.split("/").last # e.g., "21047466-cheshire"
        @user_id, @slug = user_id_and_slug.split("-")
        puts "#{Util::SUCCESS_EMOJI} Signed in to Goodreads as #{@profile_name}"
      end

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        @agent.get("#{BASE_URL}#{path}")
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        {
          "email" => @email,
          "password" => @password,
          "profile_name" => @profile_name,
          "user_id" => @user_id,
          "slug" => @slug,
        }
      end

      sig { params(cred_client: Database::Credentials).void }
      def save_to_database(cred_client)
        cred_client.upsert(key: CREDENTIALS_DB_KEY, value: to_h)
      end

      sig { params(cred_client: Database::Credentials).returns(T::Boolean) }
      def load_from_database(cred_client)
        goodreads_data = cred_client.find(key: CREDENTIALS_DB_KEY)
        unless goodreads_data
          puts "#{Util::INFO_EMOJI} No Goodreads credentials found in database"
          return false
        end

        @email = goodreads_data["email"]
        @password = goodreads_data["password"]
        @profile_name = goodreads_data["profile_name"]
        @user_id = goodreads_data["user_id"]
        @slug = goodreads_data["slug"]

        true
      end
    end
  end
end

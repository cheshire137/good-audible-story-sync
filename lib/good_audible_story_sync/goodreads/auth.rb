# frozen_string_literal: true
# typed: true

require "mechanize"

module GoodAudibleStorySync
  module Goodreads
    class Auth
      extend T::Sig

      class AuthError < StandardError; end

      BASE_URL = "https://www.goodreads.com"

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
      attr_reader :email

      sig { returns Mechanize }
      attr_reader :agent

      sig { params(agent: T.nilable(Mechanize), data: T::Hash[String, T.nilable(String)]).void }
      def initialize(agent: nil, data: {})
        @agent = agent || Mechanize.new
        @email = data["email"]
        @password = data["password"]
      end

      sig { params(session_id: String, session_token: String, session_id_time: String, sess_at_main: String, ubid_main: String, x_main: String, at_main: String).void }
      def sign_in(session_id:, session_token:, session_id_time:, sess_at_main:, ubid_main:, x_main:, at_main:)
        raise AuthError.new("Cannot sign in without credentials") if @email.nil? || @password.nil?

        puts "#{Util::INFO_EMOJI} Signing into Goodreads as #{@email}..."
        select_sign_in_page = begin
          get("/user/sign_in")
        rescue Errno::ETIMEDOUT => err
          raise AuthError.new("Failed to load Goodreads: #{err}")
        end

        email_sign_in_link = T.let(select_sign_in_page.link_with(text: /Sign in with email/),
          T.nilable(Mechanize::Page::Link))
        raise AuthError.new("Failed to find sign-in link on #{select_sign_in_page.uri}") unless email_sign_in_link

        email_sign_in_page = email_sign_in_link.click
        sign_in_form = T.let(email_sign_in_page.form_with(name: "signIn"), T.nilable(Mechanize::Form))
        raise AuthError.new("Could not find sign-in form on #{email_sign_in_page.uri}") unless sign_in_form

        email_field = sign_in_form.field_with(name: "email")
        raise AuthError.new("Could not find email field in sign-in form") unless email_field
        password_field = sign_in_form.field_with(name: "password")
        raise AuthError.new("Could not find password field in sign-in form") unless password_field

        email_field.value = @email
        password_field.value = @password
        begin
          sign_in_form.submit
        rescue Mechanize::ResponseCodeError => err
          raise AuthError.new("Error signing into Goodreads: #{err}")
        end

        set_cookie("session-id", session_id)
        set_cookie("session-token", session_token)
        set_cookie("session-id-time", session_id_time)
        set_cookie("sess-at-main", sess_at_main)
        set_cookie("ubid-main", ubid_main)
        set_cookie("x-main", x_main)
        set_cookie("likely_has_account", "true")
        set_cookie("at_main", at_main)

        # successful_sign_in = !self.class.sign_in_page?(page_after_sign_in)
        # raise AuthError.new("Could not log in to Goodreads") unless successful_sign_in
      end

      def set_cookie(key, value)
        uri = agent.history.last.uri
        puts "#{Util::INFO_EMOJI} Setting cookie #{key} for #{uri}"
        cookie = Mechanize::Cookie.new(key, value)
        cookie.domain = ".goodreads.com"
        cookie.path = "/"
        @agent.cookie_jar.add(uri, cookie)
      end

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        @agent.get("#{BASE_URL}#{path}")
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        { "email" => @email, "password" => @password }
      end
    end
  end
end

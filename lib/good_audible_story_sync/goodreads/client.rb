# frozen_string_literal: true
# typed: true

require "mechanize"
require "rainbow"

module GoodAudibleStorySync
  module Goodreads
    class Client
      extend T::Sig

      BASE_URL = Auth::BASE_URL

      class NotAuthenticatedError < StandardError; end

      sig { returns Mechanize }
      attr_reader :agent

      sig { params(auth: Auth).void }
      def initialize(auth:)
        @agent = T.let(auth.agent, Mechanize)
        @auth = auth
      end

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        url = "#{BASE_URL}#{path}"
        puts "#{Util::INFO_EMOJI} GET #{Rainbow(url).blue}"
        load_page(-> { @agent.get(url) })
      end

      private

      sig { params(make_request: T.proc.returns(Mechanize::Page)).returns(Mechanize::Page) }
      def load_page(make_request)
        page = make_request.call
        raise NotAuthenticatedError if Auth.sign_in_page?(page)
        sleep 1 # don't hammer the server
        page
      end
    end
  end
end

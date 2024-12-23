# frozen_string_literal: true
# typed: true

require "mechanize"

module GoodAudibleStorySync
  module Storygraph
    class Client
      extend T::Sig

      BASE_URL = Auth::BASE_URL

      class NotAuthenticatedError < StandardError; end

      sig { params(auth: Auth).void }
      def initialize(auth:)
        @agent = auth.agent
        @auth = auth
      end

      sig { returns T.untyped }
      def get_read_books
        url = "#{BASE_URL}/books-read/#{@auth.username}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        page = load_page(-> { @agent.get(url) })
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_by_isbn(isbn)
        result_link = T.let(search(isbn).first, T.nilable(Nokogiri::XML::Element))
        return unless result_link

        Book.from_search_result(result_link, base_url: BASE_URL, extra_data: { "isbn" => isbn })
      end

      private

      sig { params(make_request: T.proc.returns(Mechanize::Page)).returns(Mechanize::Page) }
      def load_page(make_request)
        page = make_request.call
        raise NotAuthenticatedError if Auth.sign_in_page?(page)
        page
      end

      sig { params(query: String).returns(Nokogiri::XML::NodeSet) }
      def search(query)
        raise "No search query provided" if query.strip.empty?

        params = { "search_term" => query }
        url = "#{BASE_URL}/search?#{URI.encode_www_form(params)}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        page = load_page(-> { @agent.get(url) })
        T.let(page.search("#search-results-ul li a"), Nokogiri::XML::NodeSet)
      end
    end
  end
end

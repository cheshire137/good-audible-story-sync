# frozen_string_literal: true
# typed: true

require "mechanize"

module GoodAudibleStorySync
  module Storygraph
    class Client
      extend T::Sig

      BASE_URL = "https://app.thestorygraph.com"

      sig { params(auth: Auth).void }
      def initialize(auth:)
        @agent = Mechanize.new
        @auth = auth
      end

      sig { params(query: String).returns(Nokogiri::XML::NodeSet) }
      def search(query)
        raise "No search query provided" if query.strip.empty?

        puts "#{Util::INFO_EMOJI} Searching Storygraph for '#{query}'..."
        params = { "search_term" => query }
        url = "#{BASE_URL}/search?#{URI.encode_www_form(params)}"
        results_page = @agent.get(url)
        T.let(results_page.search("#search-results-ul li a"), Nokogiri::XML::NodeSet)
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_by_isbn(isbn)
        result_link = T.let(search(isbn).first, T.nilable(Nokogiri::XML::Element))
        return unless result_link

        Book.from_search_result(result_link, base_url: BASE_URL, extra_data: { "isbn" => isbn })
      end
    end
  end
end

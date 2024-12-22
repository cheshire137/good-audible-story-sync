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

      sig { params(query: String).returns(T::Array[Book]) }
      def search(query)
        raise "No search query provided" if query.strip.empty?

        puts "#{Util::INFO_EMOJI} Searching Storygraph for '#{query}'..."
        params = { "search_term" => query }
        url = "#{BASE_URL}/search?#{URI.encode_www_form(params)}"
        results_page = @agent.get(url)
        result_links = T.let(results_page.search("#search-results-ul li a"),
          Nokogiri::XML::NodeSet)
        result_links.map { |element| Book.new(element, base_url: BASE_URL) }
      end
    end
  end
end

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

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        url = "#{BASE_URL}#{path}"
        puts "#{Util::INFO_EMOJI} GET #{url}"
        load_page(-> { @agent.get(url) })
      end

      # e.g., https://app.thestorygraph.com/books-read/cheshire137
      sig { params(page: Integer, load_all_pages: T::Boolean).returns(Library) }
      def get_read_books(page: 1, load_all_pages: true)
        initial_page = get("/books-read/#{@auth.username}?page=#{page}")

        filter_header_prefix = "Filter list "
        filter_header_el = initial_page.search(".filter-menu *").detect do |el|
          el.text.start_with?(filter_header_prefix)
        end
        total_books = if filter_header_el
          filter_header_el.text.split(filter_header_prefix).last.gsub(/[^0-9]/, "").to_i
        end

        library = Library.new(total_books: total_books)
        books = get_read_books_on_page(page: initial_page, load_all_pages: load_all_pages)
        books.each { |book| library.add_book(book) }
        library
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

      # e.g., https://app.thestorygraph.com/search?search_term=midnight%20chernobyl
      sig { params(query: String).returns(Nokogiri::XML::NodeSet) }
      def search(query)
        raise "No search query provided" if query.strip.empty?

        params = { "search_term" => query }
        page = get("/search?#{URI.encode_www_form(params)}")
        T.let(page.search("#search-results-ul li a"), Nokogiri::XML::NodeSet)
      end

      sig do
        params(
          path: T.nilable(String),
          page: T.nilable(Mechanize::Page),
          load_all_pages: T::Boolean
        ).returns(T::Array[Book])
      end
      def get_read_books_on_page(path: nil, page: nil, load_all_pages: true)
        if path
          page = get(path)
        elsif page.nil?
          raise "Either a relative URL or a page must be provided"
        end

        book_elements = T.let(page.search(".read-books-panes .book-pane"), Nokogiri::XML::NodeSet)
        books = book_elements.map do |book_element|
          Book.from_read_book(book_element, base_url: BASE_URL)
        end

        if load_all_pages
          next_page_link = page.at(".read-books #next_link")
          if next_page_link
            units = books.size == 1 ? "book" : "books"
            puts "#{Util::INFO_EMOJI} Found #{books.size} #{units} on page"

            books += get_read_books_on_page(path: next_page_link["href"],
              load_all_pages: load_all_pages)
          end
        end

        books
      end
    end
  end
end

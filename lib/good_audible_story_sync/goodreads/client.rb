# frozen_string_literal: true
# typed: true

require "mechanize"
require "rainbow"

module GoodAudibleStorySync
  module Goodreads
    class Client
      extend T::Sig

      BASE_URL = Auth::BASE_URL

      class Error < StandardError; end
      class NotAuthenticatedError < StandardError; end

      sig { returns Mechanize }
      attr_reader :agent

      sig { params(auth: Auth).void }
      def initialize(auth:)
        @agent = T.let(auth.agent, Mechanize)
        @auth = auth
      end

      # e.g., https://www.goodreads.com/review/list/21047466-cheshire?shelf=read
      sig do
        params(
          page: Integer,
          load_all_pages: T::Boolean,
          process_book: T.nilable(T.proc.params(arg0: Book).void)
        ).returns(Library)
      end
      def get_read_books(page: 1, load_all_pages: true, process_book: nil)
        initial_page = get("/review/list/#{@auth.user_id}-#{@auth.slug}?shelf=read&page=#{page}")
        library = Library.new
        books = get_read_books_on_page(page: initial_page, load_all_pages: load_all_pages,
          process_book: process_book)
        books.each { |book| library.add_book(book) }
        library
      end

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        url = "#{BASE_URL}#{path}"
        puts "#{Util::INFO_EMOJI} GET #{Rainbow(url).blue}"
        load_page(-> { @agent.get(url) })
      end

      private

      sig do
        params(
          path: T.nilable(String),
          page: T.nilable(Mechanize::Page),
          load_all_pages: T::Boolean,
          process_book: T.nilable(T.proc.params(arg0: Book).void)
        ).returns(T::Array[Book])
      end
      def get_read_books_on_page(path: nil, page: nil, load_all_pages: true, process_book: nil)
        if path
          page = get(path)
        elsif page.nil?
          raise "Either a relative URL or a page must be provided"
        end

        book_elements = T.let(page.search("table#books tbody tr"), Nokogiri::XML::NodeSet)
        books = book_elements.map { |el| Book.from_book_list(el, page: page) }
        puts "#{Util::WARNING_EMOJI} No books found on #{page.uri}" if books.empty?
        books.each { |book| process_book.call(book) } if process_book

        if load_all_pages
          next_page_link = page.at("a.next_page")
          if next_page_link
            units = books.size == 1 ? "book" : "books"
            print "#{Util::INFO_EMOJI} Found #{books.size} #{units} on page"
            last_book = books.last
            print ", ending with #{last_book.title_and_author}" if last_book
            puts

            books += get_read_books_on_page(path: next_page_link["href"],
              load_all_pages: load_all_pages, process_book: process_book)
          end
        end

        books
      end

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

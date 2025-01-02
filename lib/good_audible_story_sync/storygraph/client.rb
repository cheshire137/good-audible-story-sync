# frozen_string_literal: true
# typed: true

require "mechanize"
require "rainbow"

module GoodAudibleStorySync
  module Storygraph
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

      sig { params(book_id: String).returns(T::Boolean) }
      def mark_as_read(book_id)
        page = get("/books/#{book_id}")
        action_regex = /book_id=#{book_id}&status=read/
        form = page.forms.detect { |f| f.action =~ action_regex }
        unless form
          puts "#{Util::ERROR_EMOJI} Could not find form to mark book as read"
          return false
        end
        form.submit
        true
      end

      sig { params(book_id: String, finish_date: Date).returns(T::Boolean) }
      def set_read_date(book_id, finish_date)
        page = get("/books/#{book_id}")
        link = page.link_with(text: /Click to add a read date/) ||
          page.link_with(text: /Click to edit read date/)
        unless link
          puts "#{Util::ERROR_EMOJI} Could not find link to show read-date form"
          return false
        end

        update_file = T.let(link.click, Mechanize::File)
        update_page = Mechanize::Page.new(page.uri, page.response, update_file.body, page.code, @agent)
        action_regex = /^\/read_instances\//
        form = update_page.forms.detect { |f| f.action =~ action_regex }
        unless form
          puts "#{Util::ERROR_EMOJI} Could not find form to update read date"
          return false
        end

        end_day_field = form.field_with(name: "read_instance[day]")
        unless end_day_field
          puts "#{Util::ERROR_EMOJI} Could not find day field in read-date form"
          return false
        end

        end_month_field = form.field_with(name: "read_instance[month]")
        unless end_month_field
          puts "#{Util::ERROR_EMOJI} Could not find month field in read-date form"
          return false
        end

        end_year_field = form.field_with(name: "read_instance[year]")
        unless end_year_field
          puts "#{Util::ERROR_EMOJI} Could not find year field in read-date form"
          return false
        end

        end_year_field.value = finish_date.year
        end_month_field.value = finish_date.month
        end_day_field.value = finish_date.day

        form.submit

        true
      end

      sig { params(book_id: String).returns(T::Boolean) }
      def set_currently_reading(book_id)
        page = get("/books/#{book_id}")
        action_regex = /book_id=#{book_id}&status=currently-reading$/
        form = page.forms.detect { |f| f.action =~ action_regex }
        return false unless form
        form.submit
        true
      end

      sig { params(path: String).returns(Mechanize::Page) }
      def get(path)
        url = "#{BASE_URL}#{path}"
        puts "#{Util::INFO_EMOJI} GET #{Rainbow(url).blue}"
        load_page(-> { @agent.get(url) })
      end

      # e.g., https://app.thestorygraph.com/books-read/cheshire137
      sig do
        params(
          page: Integer,
          load_all_pages: T::Boolean,
          process_book: T.nilable(T.proc.params(arg0: Book).void)
        ).returns(Library)
      end
      def get_read_books(page: 1, load_all_pages: true, process_book: nil)
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
        books.each do |book|
          library.add_book(book)
          process_book.call(book) if process_book
        end
        library
      end

      sig { params(isbn: String, fallback_query: T.nilable(String)).returns(T.nilable(Book)) }
      def find_by_isbn(isbn, fallback_query: nil)
        result_link = search(isbn).first
        if result_link.nil? && fallback_query
          puts "#{Util::WARNING_EMOJI} No results for ISBN #{isbn}, searching for '#{fallback_query}'"
          result_link = search(fallback_query).first
        end
        return unless result_link

        load_book_search_result(result_link, extra_data: { "isbn" => isbn })
      end

      sig { params(link: Mechanize::Page::Link, extra_data: T::Hash[String, T.untyped]).returns(Book) }
      def load_book_search_result(link, extra_data: {})
        page = link.click

        other_edition_link = page.link_with(text: /You've read another edition/)
        if other_edition_link
          page = other_edition_link.click
        end

        Book.from_book_page(page, extra_data: extra_data)
      end

      # e.g., https://app.thestorygraph.com/search?search_term=midnight%20chernobyl
      sig { params(query: String).returns(T::Array[Mechanize::Page::Link]) }
      def search(query)
        raise "No search query provided" if query.strip.empty?

        params = { "search_term" => query }
        page = get("/search?#{URI.encode_www_form(params)}")
        search_results_list = page.at("#search-results-ul")
        return [] unless search_results_list

        links = page.links.select { |link| link.node.ancestors.include?(search_results_list) }
        links.reject { |link| link.text.strip.start_with?("View all results") }
      end

      private

      sig { params(make_request: T.proc.returns(Mechanize::Page)).returns(Mechanize::Page) }
      def load_page(make_request)
        page = make_request.call
        raise NotAuthenticatedError if Auth.sign_in_page?(page)
        sleep 1 # don't hammer the server
        page
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
          Book.from_read_book(book_element, page: page)
        end

        if load_all_pages
          next_page_link = page.at(".read-books #next_link")
          if next_page_link
            units = books.size == 1 ? "book" : "books"
            print "#{Util::INFO_EMOJI} Found #{books.size} #{units} on page"
            last_book = books.last
            print ", ending with #{last_book.title_and_author}" if last_book
            puts

            books += get_read_books_on_page(path: next_page_link["href"],
              load_all_pages: load_all_pages)
          end
        end

        books
      end
    end
  end
end

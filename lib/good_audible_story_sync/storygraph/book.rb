# frozen_string_literal: true
# typed: true

require "date"
require "rainbow"

module GoodAudibleStorySync
  module Storygraph
    class Book
      extend T::Sig

      class Status < T::Enum
        enums do
          CurrentlyReading = new("currently reading")
          DidNotFinish = new("did not finish")
          ToRead = new("to read")
          Read = new("read")
        end
      end

      # Public: From .book-pane element on a URL like
      # https://app.thestorygraph.com/books-read/cheshire137.
      sig do
        params(
          book_pane: Nokogiri::XML::Element,
          page: Mechanize::Page,
          extra_data: T::Hash[String, T.untyped]
        ).returns(Book)
      end
      def self.from_read_book(book_pane, page:, extra_data: {})
        title_link = book_pane.at(".book-title-author-and-series h3 a")
        raise "No title link found on #{page.uri}" unless title_link

        author_el = book_pane.search(".book-title-author-and-series p").last
        read_status_label = book_pane.at(".read-status-label")

        new({
          "title" => Util.squish(title_link.text.strip),
          "author" => Util.squish(author_el&.text&.strip),
          "url" => "#{page.uri.origin}#{title_link["href"]}",
          "id" => book_pane["data-book-id"],
          "finished_on" => extract_finish_date(book_pane),
          "status" => status_from_read_status_label(read_status_label) || Status::Read.serialize,
        }.merge(extra_data))
      end

      # Public: From a page like
      # https://app.thestorygraph.com/books/96b3360a-289c-4e1c-b463-f9f0f5b72a0e.
      sig { params(page: Mechanize::Page, extra_data: T::Hash[String, T.untyped]).returns(Book) }
      def self.from_book_page(page, extra_data: {})
        title_header = page.at(".book-title-author-and-series h3")
        raise "No title header found on page #{page.uri}" unless title_header

        book_id_node = page.at("[data-book-id]")
        book_id = if book_id_node
          book_id_node["data-book-id"]
        else
          page.uri.path.split("/books/").last
        end

        author_link = page.at(".book-title-author-and-series a")
        read_status_label = page.at(".read-status-label")

        new({
          "id" => book_id,
          "title" => Util.squish(title_header.text.strip),
          "author" => Util.squish(author_link&.text&.strip),
          "url" => page.uri.to_s,
          "finished_on" => extract_finish_date(page),
          "status" => status_from_read_status_label(read_status_label),
        }.merge(extra_data))
      end

      sig { params(read_status_label: T.nilable(Nokogiri::XML::Element)).returns(T.nilable(Status)) }
      def self.status_from_read_status_label(read_status_label)
        return unless read_status_label
        read_status = read_status_label.text.strip.downcase
        Status.try_deserialize(read_status)
      end

      sig { params(data: T::Hash[String, T.untyped]).void }
      def initialize(data)
        @data = data
      end

      sig { returns T.nilable(Date) }
      def finished_on
        return @finished_on if defined?(@finished_on)
        date_or_str = @data["finished_on"]
        return if date_or_str.nil?
        @finished_on = date_or_str.is_a?(String) ? Date.parse(date_or_str) : date_or_str
      end

      sig { params(value: T.nilable(Date)).void }
      def finished_on=(value)
        @finished_on = value
        @data["finished_on"] = value.to_s
      end

      sig { returns T::Boolean }
      def finished?
        !finished_on.nil? || status == Status::Read
      end

      sig { returns T::Boolean }
      def currently_reading?
        status == Status::CurrentlyReading
      end

      sig { returns T::Boolean }
      def did_not_finish?
        status == Status::DidNotFinish
      end

      sig { returns T::Boolean }
      def want_to_read?
        status == Status::ToRead
      end

      sig { params(other_book: Book).returns(T::Boolean) }
      def copy_from(other_book)
        unless id == other_book.id
          raise "Cannot merge Storygraph books with different IDs: #{id} and #{other_book.id}"
        end

        puts "#{Util::INFO_EMOJI} Updating book info for #{id}..."
        any_updates = T.let(false, T::Boolean)

        other_book.to_h.each do |key, value|
          next unless value

          if @data[key].nil? || @data[key].is_a?(String) && @data[key].empty?
            puts "#{Util::TAB}Setting #{key} => #{value}"
            @data[key] = value
            any_updates = true
          end
        end

        any_updates
      end

      sig { returns T.nilable(String) }
      def id
        @data["id"]
      end

      sig { returns T.nilable(String) }
      def isbn
        @data["isbn"]
      end

      sig { returns T.nilable(Status) }
      def status
        value = @data["status"]
        Status.try_deserialize(value) if value
      end

      sig { params(stylize: T::Boolean).returns(T.nilable(String)) }
      def title(stylize: false)
        value = @data["title"]
        return value unless stylize && value
        Rainbow(value).underline
      end

      sig { returns T.nilable(String) }
      def author
        @data["author"]
      end

      sig { params(stylize: T::Boolean).returns(T.nilable(String)) }
      def url(stylize: false)
        @url_by_stylize ||= {}
        return @url_by_stylize[stylize] if @url_by_stylize[stylize]
        value = @data["url"] || "#{Client::BASE_URL}/books/#{id}"
        @url_by_stylize[stylize] = if stylize
          Rainbow(value).blue
        else
          value
        end
      end

      sig { params(books_db: Database::StorygraphBooks).returns(T::Boolean) }
      def save_to_database(books_db)
        id = self.id
        return false unless id

        books_db.upsert(id: id, title: title, author: author, finished_on: finished_on,
          isbn: isbn, status: status&.serialize)

        true
      end

      sig { params(indent_level: Integer, stylize: T::Boolean).returns(String) }
      def to_s(indent_level: 0, stylize: false)
        line1 = "#{Util::TAB * indent_level}#{title_and_author(stylize: stylize)}" \
          "#{status_summary(stylize: stylize)}"
        lines = [
          line1,
          "#{Util::TAB * (indent_level + 1)}#{Util::NEWLINE_EMOJI} #{url(stylize: stylize)}",
        ]
        lines.join("\n")
      end

      sig { params(stylize: T::Boolean).returns(String) }
      def title_and_author(stylize: false)
        @title_and_author_by_stylize ||= {}
        return @title_and_author_by_stylize[stylize] if @title_and_author_by_stylize[stylize]
        author = self.author
        @title_and_author_by_stylize[stylize] = if author && !author.empty?
          "#{title(stylize: stylize)} by #{author}"
        else
          title(stylize: stylize) || "Unknown (ID #{id})"
        end
      end

      sig { params(prefix: String, stylize: T::Boolean).returns(T.nilable(String)) }
      def status_summary(prefix: " - ", stylize: false)
        finished_on = self.finished_on
        suffix = if finished_on
          "Finished #{Util.pretty_date(finished_on)}"
        elsif finished?
          "Finished"
        elsif currently_reading?
          "Currently reading"
        elsif did_not_finish?
          "Did not finish"
        elsif want_to_read?
          "Want to read"
        else
          status&.serialize || "Unknown"
        end
        value = "#{prefix}#{suffix}"
        stylize ? Rainbow(value).italic : value
      end

      sig { returns String }
      def inspect
        @data.inspect
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        @data.dup
      end

      sig do
        params(node_or_page: T.any(Nokogiri::XML::Element, Mechanize::Page)).returns(T.nilable(String))
      end
      def self.extract_finish_date(node_or_page)
        finish_date_prefix = "Finished "
        finished_el = node_or_page.search(".action-menu p").detect do |el|
          el.text.start_with?(finish_date_prefix)
        end
        if finished_el
          # e.g., "Dec 20, 2024\n              \n                Click to edit read date"
          date_str_and_extra = finished_el.text.split(finish_date_prefix).last

          # e.g., "Dec 20, 2024"
          date_str_and_extra.split("\n").first
        end
      end
      private_class_method :extract_finish_date
    end
  end
end

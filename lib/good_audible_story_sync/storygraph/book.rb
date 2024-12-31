# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Storygraph
    class Book
      extend T::Sig

      # Public: From .book-list-option element on a URL like
      # https://app.thestorygraph.com/search?search_term=9781508278511.
      sig do
        params(
          node: Nokogiri::XML::Element,
          base_url: String,
          extra_data: T::Hash[String, T.untyped]
        ).returns(Book)
      end
      def self.from_search_result(node, base_url:, extra_data: {})
        path = node["href"]
        id = if node["id"]
          node["id"].split("search_result_book_").last
        elsif path&.start_with?("/books/")
          path.split("/books/").last
        end
        new({
          "title" => node.at("h1:not(.sr-only)")&.text,
          "author" => node.at("h2:not(.sr-only)")&.text,
          "url" => "#{base_url}#{path}",
          "id" => id,
        }.merge(extra_data))
      end

      # Public: From .book-pane element on a URL like
      # https://app.thestorygraph.com/books-read/cheshire137.
      sig do
        params(
          node: Nokogiri::XML::Element,
          base_url: String,
          extra_data: T::Hash[String, T.untyped]
        ).returns(Book)
      end
      def self.from_read_book(node, base_url:, extra_data: {})
        title_link = node.at(".book-title-author-and-series h3 a")
        raise "No title link found" unless title_link

        finish_date_prefix = "Finished "
        finished_el = node.search(".action-menu p").detect do |el|
          el.text.start_with?(finish_date_prefix)
        end
        finished_date_str = if finished_el
          # e.g., "Dec 20, 2024\n              \n                Click to edit read date"
          date_str_and_extra = finished_el.text.split(finish_date_prefix).last

          # e.g., "Dec 20, 2024"
          date_str_and_extra.split("\n").first
        end

        new({
          "title" => title_link.text.strip,
          "author" => node.at(".book-title-author-and-series p")&.text&.strip,
          "url" => base_url + title_link["href"],
          "id" => node["data-book-id"],
          "finished_on" => finished_date_str,
        }.merge(extra_data))
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

      sig { returns T::Boolean }
      def finished?
        !finished_on.nil?
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

      sig { returns T.nilable(String) }
      def title
        @data["title"]
      end

      sig { returns T.nilable(String) }
      def author
        @data["author"]
      end

      sig { returns T.nilable(String) }
      def url
        @url ||= if @data["url"]
          @data["url"]
        else
          "#{Client::BASE_URL}/books/#{id}"
        end
      end

      sig { params(books_db: Database::StorygraphBooks).returns(T::Boolean) }
      def save_to_database(books_db)
        id = self.id
        return false unless id

        books_db.upsert(id: id, title: title, author: author, finished_on: finished_on,
          isbn: isbn)

        true
      end

      sig { params(indent_level: Integer).returns(String) }
      def to_s(indent_level: 0)
        lines = [
          "#{Util::TAB * indent_level}#{title_and_author}",
          "#{Util::TAB * (indent_level + 1)}#{Util::NEWLINE_EMOJI} #{url}",
        ]
        lines.join("\n")
      end

      sig { returns String }
      def title_and_author
        return @title_and_author if @title_and_author
        author = self.author
        @title_and_author = if author && !author.empty?
          "#{title} by #{author}"
        else
          title || "Unknown (ID #{id})"
        end
      end

      sig { returns String }
      def inspect
        @data.inspect
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        @data.dup
      end
    end
  end
end

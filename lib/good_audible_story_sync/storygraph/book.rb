# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Storygraph
    class Book
      extend T::Sig

      sig do
        params(
          node: Nokogiri::XML::Element,
          base_url: String,
          extra_data: T::Hash[String, T.untyped]
        ).returns(Book)
      end
      def self.from_search_result(node, base_url:, extra_data: {})
        new({
          "title" => node.at("h1:not(.sr-only)")&.text,
          "author" => node.at("h2:not(.sr-only)")&.text,
          "url" => base_url + node["href"],
        }.merge(extra_data))
      end

      # Public: From .book-pane element on a URL like
      # https://app.thestorygraph.com/books-read/cheshire137.
      sig { params(node: Nokogiri::XML::Element, base_url: String).returns(Book) }
      def self.from_read_book(node, base_url:)
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
          "title" => title_link.text,
          "author" => node.at(".book-title-author-and-series h3 p")&.text,
          "url" => base_url + title_link["href"],
          "id" => node["data-book-id"],
          "finished_on" => finished_date_str,
        })
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
          "#{Util::TAB * indent_level}#{title} by #{author}",
          "#{Util::TAB * (indent_level + 1)}#{Util::NEWLINE_EMOJI} #{url}",
        ]
        lines.join("\n")
      end

      sig { returns String }
      def inspect
        @data.inspect
      end

      sig { returns T::Hash[String, T.untyped] }
      def to_h
        @data
      end
    end
  end
end

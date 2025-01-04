# frozen_string_literal: true
# typed: true

require "uri"

module GoodAudibleStorySync
  module Goodreads
    class Book
      extend T::Sig

      class Status < T::Enum
        enums do
          CurrentlyReading = new("currently-reading")
          WantToRead = new("to-read")
          Read = new("read")
        end
      end

      # Public: From a `.bookList .book` element on the mobile view of a page like
      # https://www.goodreads.com/review/list/21047466-cheshire?shelf=read.
      sig { params(node: Nokogiri::XML::Element).returns(Book) }
      def self.from_book_list(node)
        name_el = node.at("[itemprop=name]")
        raise "Could not find itemprop=name element for book list item on #{node.document.url}" unless name_el
        link = name_el.at("a")
        raise "Could not find book link for #{name_el.text} on #{node.document.url}" unless link
        url = URI.parse(link["href"])
        author_el = node.at("[itemprop=author]")
        current_shelf_el = node.at("[data-current-shelf]")
        new({
          "title" => Util.squish(name_el.text),
          "url" => url, # e.g., "/book/show/11286.Carrion_Comfort"
          "slug" => url.path&.split("/")&.last, # e.g., "11286.Carrion_Comfort"
          "author" => Util.squish(author_el&.at("div")&.text),
          "status" => current_shelf_el ? current_shelf_el["data-current-shelf"] : nil, # e.g., "to-read"
        })
      end

      sig { params(data: T::Hash[String, T.untyped]).void }
      def initialize(data)
        @data = data
        raise "Cannot create a Goodreads book without a slug" unless @data["slug"] && !@data["slug"].empty?
      end

      sig { returns String }
      def slug
        @data["slug"]
      end

      sig { returns T.nilable(String) }
      def title
        @data["title"]
      end

      sig { returns T.nilable(String) }
      def author
        @data["author"]
      end

      sig { returns T.nilable(Status) }
      def status
        value = @data["status"]
        return value if value.nil? || value.is_a?(Status)
        Status.try_deserialize(value.to_s)
      end

      sig { returns T::Boolean }
      def finished?
        status == Status::Read
      end

      sig { returns T.nilable(String) }
      def url
        @data["url"]
      end
    end
  end
end

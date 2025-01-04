# frozen_string_literal: true
# typed: true

require "rainbow"
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

      # Public: From a `table#books tbody tr` element on a page like
      # https://www.goodreads.com/review/list/21047466-cheshire?shelf=read.
      sig { params(node: Nokogiri::XML::Element, page: Mechanize::Page).returns(Book) }
      def self.from_book_list(node, page:)
        name_el = node.at(".field.title .value")
        raise "Could not find itemprop=name element for book list item on #{node.document.url}" unless name_el
        link = name_el.at("a")
        raise "Could not find book link for #{name_el.text} on #{node.document.url}" unless link
        url = URI.parse(link["href"])
        url.hostname ||= page.uri.hostname
        url.scheme ||= page.uri.scheme
        author_el = node.at(".field.author .value")
        author = if author_el
          value = author_el.text.strip
          if value.include?(", ") # e.g., "Simmons, Dan"
            value = value.split(", ").reverse.join(" ")
          end
          value
        end
        current_shelf_link = node.at(".field.shelves .value a")
        new({
          "title" => Util.squish(name_el.text),
          "url" => url, # e.g., "https://www.goodreads.com/book/show/11286.Carrion_Comfort"
          "slug" => url.path&.split("/")&.last, # e.g., "11286.Carrion_Comfort"
          "author" => author,
          "status" => current_shelf_link&.text, # e.g., "to-read"
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

      sig { returns T::Boolean }
      def currently_reading?
        status == Status::CurrentlyReading
      end

      sig { returns T::Boolean }
      def want_to_read?
        status == Status::WantToRead
      end

      sig { params(stylize: T::Boolean).returns(T.nilable(String)) }
      def url(stylize: false)
        @url_by_stylize ||= {}
        return @url_by_stylize[stylize] if @url_by_stylize[stylize]
        value = @data["url"] || "#{Client::BASE_URL}/book/show/#{slug}"
        @url_by_stylize[stylize] = if stylize
          Rainbow(value).blue
        else
          value
        end
      end

      sig { params(stylize: T::Boolean).returns(String) }
      def title_and_author(stylize: false)
        @title_and_author_by_stylize ||= {}
        return @title_and_author_by_stylize[stylize] if @title_and_author_by_stylize[stylize]
        author = self.author
        @title_and_author_by_stylize[stylize] = if author && !author.empty?
          "#{title(stylize: stylize)} by #{author}"
        else
          title(stylize: stylize) || "Unknown (slug #{slug})"
        end
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

      sig { params(prefix: String, stylize: T::Boolean).returns(T.nilable(String)) }
      def status_summary(prefix: " - ", stylize: false)
        suffix = if finished?
          "Finished"
        elsif currently_reading?
          "Currently reading"
        elsif want_to_read?
          "Want to read"
        else
          status&.serialize
        end
        if suffix
          value = "#{prefix}#{suffix}"
          stylize ? Rainbow(value).italic : value
        end
      end
    end
  end
end

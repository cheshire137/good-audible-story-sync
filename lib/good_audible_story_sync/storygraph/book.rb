# frozen_string_literal: true
# typed: true

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
        Book.new({
          "title" => node.search("h1:not(.sr-only)").first&.text,
          "author" => node.search("h2:not(.sr-only)").first&.text,
          "url" => base_url + node["href"],
        }.merge(extra_data))
      end

      sig { params(data: T::Hash[String, T.untyped]).void }
      def initialize(data)
        @data = data
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
        @data["url"]
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

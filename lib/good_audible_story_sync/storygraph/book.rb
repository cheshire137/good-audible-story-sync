# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class Book
      extend T::Sig

      sig { params(search_result_node: Nokogiri::XML::Element, base_url: String).void }
      def initialize(search_result_node, base_url:)
        @search_result_node = search_result_node
        @base_url = base_url
      end

      sig { returns T.nilable(String) }
      def title
        return @title if defined?(@title)
        @title = @search_result_node.search("h1:not(.sr-only)").first&.text
      end

      sig { returns T.nilable(String) }
      def author
        return @author if defined?(@author)
        @author = @search_result_node.search("h2:not(.sr-only)").first&.text
      end

      sig { returns String }
      def url
        @url ||= @base_url + @search_result_node["href"]
      end

      sig { params(indent_level: Integer).returns(String) }
      def to_s(indent_level: 0)
        lines = [
          "#{Util::TAB * indent_level}#{title} by #{author}",
          "#{Util::TAB * (indent_level + 1)}#{Util::NEWLINE_EMOJI} #{url}",
        ]
        lines.join("\n")
      end
    end
  end
end

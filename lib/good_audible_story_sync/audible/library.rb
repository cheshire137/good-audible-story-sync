# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Audible
    class Library
      extend T::Sig

      sig { params(file_path: String).returns(Library) }
      def self.load_from_file(file_path)
        library = new
        library.load_from_file(file_path)
        library
      end

      sig { returns T::Array[LibraryItem] }
      attr_reader :items

      sig { params(items: T::Array[LibraryItem]).void }
      def initialize(items: [])
        @items = items
        @loaded_from_file = T.let(false, T::Boolean)
      end

      sig { returns Integer }
      def total_items
        items.size
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def save_to_file(file_path)
        File.write(file_path, to_json)
        File.exist?(file_path) && !File.empty?(file_path)
      end

      sig { returns T::Boolean }
      def loaded_from_file?
        @loaded_from_file
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def load_from_file(file_path)
        return false unless File.exist?(file_path)

        json_str = File.read(file_path)
        return false if json_str.strip.empty?

        data = T.let(JSON.parse(json_str), T::Array[Hash])
        @items = data.map { |item_data| LibraryItem.new(item_data) }

        @loaded_from_file = true
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(items.map(&:to_h))
      end
    end
  end
end

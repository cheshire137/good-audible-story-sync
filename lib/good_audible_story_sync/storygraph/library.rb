# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class Library
      extend T::Sig

      sig { returns T::Array[Book] }
      attr_reader :books

      sig { void }
      def initialize
        @books = T.let([], T::Array[Book])
        @loaded_from_file = T.let(false, T::Boolean)
      end

      sig { params(book: Book).void }
      def add_book(book)
        @books << book
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def load_from_file(file_path)
        return false unless File.exist?(file_path)

        puts "#{Util::INFO_EMOJI} Loading Storygraph library from #{file_path}..."
        json_str = File.read(file_path)
        return false if json_str.strip.empty?

        data = T.let(JSON.parse(json_str), T::Array[Hash])
        data.each { |item_data| add_book(Book.new(item_data)) }

        @loaded_from_file = true
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def save_to_file(file_path)
        puts "#{Util::SAVE_EMOJI} Saving Storygraph library data to file #{file_path}..."
        File.write(file_path, to_json)
        File.exist?(file_path) && !File.empty?(file_path)
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(books.map(&:to_h))
      end

    end
  end
end

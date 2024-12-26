# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class Library
      extend T::Sig

      SYNC_TIME_KEY = "storygraph_library"

      sig { returns T::Array[Book] }
      attr_reader :books

      sig { params(total_books: T.nilable(Integer)).void }
      def initialize(total_books: nil)
        @books = T.let([], T::Array[Book])
        @total_books = total_books
      end

      sig { params(book: Book).void }
      def add_book(book)
        @books << book
      end

      sig { returns Integer }
      def total_books
        @total_books || @books.size
      end

      sig { returns String }
      def book_units
        total_books == 1 ? "book" : "books"
      end

      sig { params(db_client: Database::Client).returns(Integer) }
      def save_to_database(db_client)
        puts "#{Util::SAVE_EMOJI} Caching Storygraph library in database..."
        total_saved = 0
        books_db = db_client.storygraph_books
        books.each do |book|
          id = book.id
          if id
            success = book.save_to_database(books_db)
            total_saved += 1 if success
          else
            puts "#{Util::TAB}#{Util::WARNING_EMOJI} Skipping book with no ID: #{book}"
          end
        end
        db_client.sync_times.touch(SYNC_TIME_KEY)
        total_saved
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(books.map(&:to_h))
      end
    end
  end
end

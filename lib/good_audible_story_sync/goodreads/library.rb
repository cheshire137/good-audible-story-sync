# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Goodreads
    class Library
      extend T::Sig

      SYNC_TIME_KEY = "goodreads_library"

      sig { void }
      def initialize
        @books_by_slug = T.let({}, T::Hash[String, Book])
      end

      sig { returns T::Array[Book] }
      def books
        @books_by_slug.values
      end

      sig { params(book: Book).void }
      def add_book(book)
        @books_by_slug[book.slug] = book
      end

      sig { returns T::Array[Book] }
      def finished_books
        calculate_finished_unfinished_books
        @finished_books
      end

      sig { returns Integer }
      def total_finished
        @total_finished ||= finished_books.size
      end

      sig { returns Integer }
      def total_books
        @books_by_id.size
      end

      sig { returns Integer }
      def finished_percent
        @finished_percent ||= (total_finished.to_f / total_books * 100).round
      end

      sig { returns String }
      def finished_book_units
        total_finished == 1 ? "book" : "books"
      end

      sig { returns String }
      def book_units
        total_books == 1 ? "book" : "books"
      end

      sig { params(books_db: Database::GoodreadsBooks).returns(T::Boolean) }
      def load_from_database(books_db)
        puts "#{Util::INFO_EMOJI} Loading cached Goodreads library..."

        rows = books_db.find_all
        rows.each { |row| add_book(Book.new(row)) }

        true
      end

      sig { params(sync_times_db: Database::SyncTimes).void }
      def update_sync_time(sync_times_db)
        puts "#{Util::SAVE_EMOJI} Updating time Goodreads library was last cached..."
        sync_times_db.touch(SYNC_TIME_KEY)
      end

      sig { params(limit: Integer, stylize: T::Boolean).returns(String) }
      def to_s(limit: 5, stylize: false)
        [
          "📚 Found #{total_books} #{book_units} on Goodreads",
          finished_books_summary(limit: limit, stylize: stylize),
        ].compact.join("\n")
      end

      sig { params(limit: Integer, stylize: T::Boolean).returns(String) }
      def finished_books_summary(limit: 5, stylize: false)
        lines = T.let([
          "#{Util::DONE_EMOJI} #{total_finished} #{finished_book_units} " \
            "(#{finished_percent}%) in Goodreads library have been finished:",
        ], T::Array[String])
        lines.concat(finished_books.take(limit).map { |book| book.to_s(indent_level: 1, stylize: stylize) })
        lines << "#{Util::TAB}..." if total_finished > limit
        lines << ""
        lines.join("\n")
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(books.map(&:to_h))
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_by_isbn(isbn)
        books.detect { |book| book.isbn == isbn }
      end

      private

      sig { void }
      def calculate_finished_unfinished_books
        return if @finished_books && @unfinished_books
        @finished_books, @unfinished_books = books.partition(&:finished?)
      end
    end
  end
end

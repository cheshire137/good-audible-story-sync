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

      private

      sig { void }
      def calculate_finished_unfinished_books
        return if @finished_books && @unfinished_books
        @finished_books, @unfinished_books = books.partition(&:finished?)
      end
    end
  end
end

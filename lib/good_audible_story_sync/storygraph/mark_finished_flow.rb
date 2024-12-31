# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class MarkFinishedFlow
      extend T::Sig

      sig do
        params(
          finish_dates_by_isbn: T::Hash[String, Date],
          library: Library,
          client: Client,
          db_client: Database::Client
        ).void
      end
      def self.run(finish_dates_by_isbn:, library:, client:, db_client:)
        new(finish_dates_by_isbn: finish_dates_by_isbn, library: library, client: client,
          db_client: db_client).run
      end

      sig do
        params(
          finish_dates_by_isbn: T::Hash[String, Date],
          library: Library,
          client: Client,
          db_client: Database::Client
        ).void
      end
      def initialize(finish_dates_by_isbn:, library:, client:, db_client:)
        @finish_dates_by_isbn = finish_dates_by_isbn
        @library = library
        @client = client
        @any_library_changes = T.let(false, T::Boolean)
        @db_client = db_client
      end

      sig { void }
      def run
        @finish_dates_by_isbn.each do |isbn, finish_date|
          process_book(isbn, finish_date)
        end
        @library.save_to_database(@db_client) if @any_library_changes
      end

      private

      sig { params(isbn: String, finish_date: Date).void }
      def process_book(isbn, finish_date)
        storygraph_book = find_storygraph_book(isbn)
        return unless storygraph_book

        storygraph_finish_date = storygraph_book.finished_on

        if storygraph_finish_date.nil?
          puts "#{Util::INFO_EMOJI} Storygraph book #{storygraph_book.title_and_author} " \
            "not marked as finished"
        elsif storygraph_finish_date == finish_date
          puts "#{Util::SUCCESS_EMOJI} Storygraph book #{storygraph_book.title_and_author} already " \
            "marked as finished on #{Util.pretty_date(finish_date)}"
        else
          puts "#{Util::WARNING_EMOJI} Storygraph book #{storygraph_book.title_and_author} " \
            "marked finished on #{Util.pretty_date(storygraph_finish_date)}, versus " \
            "Audible finish date #{Util.pretty_date(finish_date)}"
        end
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_storygraph_book(isbn)
        # Do we already have the book associated with the ISBN in the local database?
        storygraph_book = @library.find_by_isbn(isbn)

        unless storygraph_book
          # If not, search for it on Storygraph using the ISBN
          storygraph_book = @client.find_by_isbn(isbn)

          if storygraph_book
            # Associate the book with its ISBN in the local library database
            @library.add_book(storygraph_book)
            @any_library_changes = true
          else
            puts "#{Util::WARNING_EMOJI} Book with ISBN #{isbn} not found on Storygraph"
          end
        end

        storygraph_book
      end
    end
  end
end

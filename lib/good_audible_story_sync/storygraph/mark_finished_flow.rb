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

      sig { params(isbn: String, target_finish_date: Date).void }
      def process_book(isbn, target_finish_date)
        book = find_book_by_isbn(isbn)
        return unless book

        storygraph_finish_date = book.finished_on
        title_and_author = book.title_and_author(stylize: true)

        if storygraph_finish_date.nil?
          puts "#{Util::INFO_EMOJI} Storygraph book #{title_and_author} not marked as finished"
          set_finish_date_on_storygraph(book, target_finish_date)
        elsif storygraph_finish_date == target_finish_date
          puts "#{Util::SUCCESS_EMOJI} Storygraph book #{title_and_author} already " \
            "marked as finished on #{Util.pretty_date(target_finish_date)}"
        else
          puts "#{Util::WARNING_EMOJI} #{title_and_author}"
          puts "#{Util::TAB}Storygraph read date: #{Util.pretty_date(storygraph_finish_date)}"
          puts "#{Util::TAB}Versus Audible: #{Util.pretty_date(target_finish_date)}"
        end
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_book_by_isbn(isbn)
        # Do we already have the book associated with the ISBN in the local database?
        book = @library.find_by_isbn(isbn)

        unless book
          # If not, search for it on Storygraph using the ISBN
          book = @client.find_by_isbn(isbn)

          if book
            # Associate the book with its ISBN in the local library database
            @library.add_book(book)
            @any_library_changes = true
          else
            puts "#{Util::WARNING_EMOJI} Book with ISBN #{isbn} not found on Storygraph"
          end
        end

        book
      end

      sig { params(book: Book, finish_date: Date).returns(T::Boolean) }
      def set_finish_date_on_storygraph(book, finish_date)
        book_id = book.id
        unless book_id
          puts "#{Util::WARNING_EMOJI} Book #{book.title_and_author(stylize: true)} has no " \
            "Storygraph ID, cannot set read date"
          return false
        end

        puts book.to_s
        puts "Finished: #{Util.pretty_date(finish_date)}"
        print "Set read date on Storygraph? (y/n/q) "
        input = gets.chomp.downcase.strip

        if input == "q"
          puts "Goodbye!"
          exit 0
        end

        unless input == "y"
          puts "#{Util::TAB}#{Util::INFO_EMOJI} Skipping..."
          return false
        end

        success = @client.set_read_date(book_id, finish_date)
        puts "#{Util::TAB}#{Util::SUCCESS_EMOJI} Done! #{book.url(stylize: true)}" if success
        success
      end
    end
  end
end

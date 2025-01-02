# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class MarkFinishedFlow
      extend T::Sig

      class UserCommand < T::Enum
        enums do
          SetReadDate = new("r")
          NextBook = new("n")
          Cancel = new("c")
          Quit = new("q")
        end
      end

      sig do
        params(
          audible_library: Audible::Library,
          library: Library,
          client: Client,
          db_client: Database::Client
        ).void
      end
      def self.run(audible_library:, library:, client:, db_client:)
        new(audible_library: audible_library, library: library, client: client,
          db_client: db_client).run
      end

      sig do
        params(
          audible_library: Audible::Library,
          library: Library,
          client: Client,
          db_client: Database::Client
        ).void
      end
      def initialize(audible_library:, library:, client:, db_client:)
        @audible_library = audible_library
        @library = library
        @client = client
        @db_client = db_client
        @current_book = T.let(nil, T.nilable(Book))
        @current_finish_date = T.let(nil, T.nilable(Date))
        @stop_marking_finished = T.let(false, T::Boolean)
      end

      sig { void }
      def run
        finish_dates_by_isbn.each do |isbn, finish_date|
          @current_finish_date = finish_date
          process_book(isbn)
          break if @stop_marking_finished
        end
      end

      private

      sig { params(isbn: String).void }
      def process_book(isbn)
        @current_book = find_book_by_isbn(isbn)
        return unless @current_book

        storygraph_finish_date = @current_book.finished_on
        title_and_author = @current_book.title_and_author(stylize: true)

        if storygraph_finish_date.nil?
          puts "#{Util::INFO_EMOJI} Storygraph book #{title_and_author} not marked as finished"
          prompt_user_about_current_book
        elsif storygraph_finish_date == @current_finish_date
          puts "#{Util::SUCCESS_EMOJI} Storygraph book #{title_and_author} already " \
            "marked as finished on #{Util.pretty_date(@current_finish_date)}"
        else
          puts "#{Util::WARNING_EMOJI} #{title_and_author}"
          puts "#{Util::TAB}Storygraph read date: #{Util.pretty_date(storygraph_finish_date)}"
          puts "#{Util::TAB}Versus Audible: #{Util.pretty_date(T.must(@current_finish_date))}"
          prompt_user_about_current_book
        end
      end

      sig { params(isbn: String).returns(T.nilable(Book)) }
      def find_book_by_isbn(isbn)
        audible_book = @audible_library.find_by_isbn(isbn)
        if audible_book
          puts "#{Util::INFO_EMOJI}Looking up #{audible_book.to_s(stylize: true)} on Storygraph..."
        end

        # Do we already have the book associated with the ISBN in the local database?
        book = @library.find_by_isbn(isbn)

        unless book
          # If not, search for it on Storygraph using the ISBN, then by title and author
          book = @client.find_by_isbn(isbn, fallback_query: audible_book&.search_query)

          if book
            # Associate the book with its ISBN in the local library database
            @library.add_book(book)
            book.save_to_database(@db_client.storygraph_books)
          else
            puts "#{Util::WARNING_EMOJI} Book with ISBN #{isbn} not found on Storygraph"
          end
        end

        book
      end

      sig { returns UserCommand }
      def get_user_command
        cmd = T.let(nil, T.nilable(UserCommand))
        while cmd.nil?
          print "Choose an option: "
          input = gets.chomp
          cmd = UserCommand.try_deserialize(input)
          puts "Invalid command" if cmd.nil?
        end
        cmd
      end

      sig { void }
      def prompt_user_about_current_book
        book = T.must(@current_book)
        puts book.to_s
        print_options
        cmd = get_user_command
        process_command(cmd)
        puts
      end

      sig { params(cmd: UserCommand).void }
      def process_command(cmd)
        case cmd
        when UserCommand::Quit then quit
        when UserCommand::NextBook then skip_current_book
        when UserCommand::SetReadDate then set_read_date_on_current_book
        when UserCommand::Cancel then cancel
        else
          T.absurd(cmd)
        end
      end

      sig { void }
      def cancel
        @stop_marking_finished = true
      end

      sig { returns T::Boolean }
      def set_read_date_on_current_book
        book = T.must(@current_book)
        book_id = book.id
        unless book_id
          puts "#{Util::WARNING_EMOJI} Book #{book.title_and_author(stylize: true)} has no " \
            "Storygraph ID, cannot set read date"
          return false
        end

        finish_date = T.must(@current_finish_date)
        success = @client.set_read_date(book_id, finish_date)

        if success
          book.finished_on = finish_date
          book.save_to_database(@db_client.storygraph_books)
          puts "#{Util::TAB}#{Util::SUCCESS_EMOJI} Done! #{book.url(stylize: true)}"
        end

        success
      end

      sig { void }
      def skip_current_book
        puts "#{Util::TAB}#{Util::INFO_EMOJI} Skipping..."
        @current_book = nil
        @current_finish_date = nil
      end

      sig { void }
      def quit
        puts "Goodbye!"
        exit 0
      end

      sig { returns T::Hash[String, Date] }
      def finish_dates_by_isbn
        @finish_dates_by_isbn ||= @audible_library.finish_dates_by_isbn
      end

      sig { void }
      def print_options
        print_option(UserCommand::SetReadDate, "set read date to #{Util.pretty_date(T.must(@current_finish_date))}")
        print_option(UserCommand::NextBook, "next book")
        print_option(UserCommand::Cancel, "cancel")
        print_option(UserCommand::Quit, "quit")
      end

      sig { params(option: UserCommand, description: String).void }
      def print_option(option, description)
        Util.print_option(option.serialize, description)
      end
    end
  end
end

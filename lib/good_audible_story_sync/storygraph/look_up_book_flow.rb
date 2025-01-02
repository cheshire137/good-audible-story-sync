# frozen_string_literal: true
# typed: true

require "rainbow"

module GoodAudibleStorySync
  module Storygraph
    class LookUpBookFlow
      extend T::Sig

      class UserCommand < T::Enum
        enums do
          Cancel = new("c")
          Quit = new("q")
        end
      end

      sig { params(client: Client, books_db: Database::StorygraphBooks).void }
      def self.run(client:, books_db:)
        new(client: client, books_db: books_db).run
      end

      sig { params(client: Client, books_db: Database::StorygraphBooks).void }
      def initialize(client:, books_db:)
        @client = client
        @books_db = books_db
        @results = T.let([], T::Array[Mechanize::Page::Link])
        @query = T.let(nil, T.nilable(String))
      end

      sig { void }
      def run
        loop do
          print_options
          cmd_or_query = get_user_command_or_query
          if cmd_or_query.is_a?(UserCommand)
            process_command(cmd_or_query)
          else
            @query = cmd_or_query
            search_storygraph
          end
          puts
        end
      end

      private

      sig { void }
      def print_options
        display_search_results if @results.size > 0
        print_option(UserCommand::Cancel, "cancel")
        print_option(UserCommand::Quit, "quit")
      end

      sig { params(option: UserCommand, description: String).void }
      def print_option(option, description)
        Util.print_option(option.serialize, description)
      end

      sig { returns T.any(UserCommand, String) }
      def get_user_command_or_query
        input = T.let(nil, T.nilable(String))
        while input.nil?
          print "Enter a search query or command: "
          input = gets.chomp
          if input.empty?
            puts "Invalid selection"
          else
            cmd = UserCommand.try_deserialize(input)
            return cmd if cmd
          end
        end
        input
      end

      sig { params(cmd: UserCommand).void }
      def process_command(cmd)
        case cmd
        when UserCommand::Cancel then cancel
        when UserCommand::Quit then quit
        else
          T.absurd(cmd)
        end
      end

      sig { params(selection: String).void }
      def process_search_result_selection(selection)
        unless Util.integer?(selection)
          puts "#{Util::ERROR_EMOJI} Invalid selection"
          return
        end

        index = selection.to_i - 1
        result = @results[index]
        unless result
          puts "#{Util::ERROR_EMOJI} Invalid selection"
          return
        end

        extra_data = {}
        if @query && Util.isbn?(@query)
          extra_data["isbn"] = @query
        end
        book = @client.load_book_search_result(result, extra_data: extra_data)
        book.save_to_database(@books_db)
        puts book.to_s(stylize: true)
        @results = []
        @query = nil
      end

      sig { void }
      def search_storygraph
        raise "No search query provided" if @query.nil?
        @results = @client.search(@query)
        if @results.empty?
          puts "#{Util::INFO_EMOJI} No results found for \"#{@query}\""
          return
        end
        prompt_user_to_pick_search_result
      end

      sig { void }
      def display_search_results
        total_results = @results.size
        units = total_results == 1 ? "result" : "results"
        puts "#{Util::INFO_EMOJI} Showing #{total_results} search #{units}:"
        @results.each_with_index do |link, i|
          display_search_result(link, i + 1)
        end
      end

      sig { params(link: Mechanize::Page::Link, number: Integer).void }
      def display_search_result(link, number)
        node = link.node
        title = Util.squish(node.at("h1:not(.sr-only)")&.text)
        author = Util.squish(node.at("h2:not(.sr-only)")&.text)
        highlighted_number = Rainbow(number.to_s).green
        print "#{highlighted_number}) "
        if title && author
          puts Rainbow(title).underline + " by #{author}"
        else
          puts link.text
        end
        url = Rainbow(link.resolved_uri.to_s).blue
        puts "#{Util::TAB}#{Util::NEWLINE_EMOJI} #{url}"
      end

      sig { void }
      def prompt_user_to_pick_search_result
        print_options
        print "Choose a book (1-#{@results.size}): "
        input = gets.chomp
        cmd = UserCommand.try_deserialize(input)
        if cmd
          process_command(cmd)
        else
          process_search_result_selection(input)
        end
      end

      sig { void }
      def cancel
      end

      sig { void }
      def quit
        puts "Goodbye!"
        exit 0
      end
    end
  end
end

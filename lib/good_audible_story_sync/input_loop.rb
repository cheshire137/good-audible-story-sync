# frozen_string_literal: true
# typed: true

require "rainbow"

module GoodAudibleStorySync
  class InputLoop
    extend T::Sig

    class UserCommand < T::Enum
      enums do
        DisplayAudibleLibrary = new("a")
        DisplayAudibleUserProfile = new("u")
        DisplayStorygraphLibrary = new("s")
        MarkFinishedBooks = new("f")
        Quit = new("q")
      end
    end

    sig { params(script_name: String).void }
    def self.run(script_name:)
      new(script_name: script_name).run
    end

    sig { params(script_name: String).void }
    def initialize(script_name:)
      @script_name = script_name
    end

    sig { void }
    def run
      options # parse command line options
      db_client # set up database tables

      loop do
        print_options
        cmd = get_user_command
        process_command(cmd)
        puts
      end
    end

    private

    sig { void }
    def print_options
      print_option(UserCommand::DisplayAudibleLibrary, "display Audible library")
      print_option(UserCommand::DisplayAudibleUserProfile, "display Audible user profile")
      print_option(UserCommand::DisplayStorygraphLibrary, "display Storygraph library")
      print_option(UserCommand::MarkFinishedBooks, "mark finished books on Storygraph")
      print_option(UserCommand::Quit, "quit")
    end

    sig { params(option: UserCommand, description: String).void }
    def print_option(option, description)
      option_letter = option.serialize
      desc_words = description.split(" ")
      word_to_highlight = desc_words.detect { |word| word.downcase.start_with?(option_letter) }
      highlighted_word_index = desc_words.index(word_to_highlight)
      highlighted_option_letter = Rainbow(option_letter).green
      highlighted_word = if word_to_highlight
        head = word_to_highlight.slice(0)
        tail = word_to_highlight.slice(1..)
        highlighted_head = Rainbow(head).green
        "#{highlighted_head}#{tail}"
      end
      highlighted_description = if highlighted_word_index
        head = (desc_words.slice(0, highlighted_word_index) || []).join(" ")
        tail = (desc_words.slice(highlighted_word_index + 1..) || []).join(" ")
        [head, highlighted_word, tail].compact.join(" ").strip
      else
        description
      end
      puts "#{highlighted_option_letter}) #{highlighted_description}"
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

    sig { params(cmd: UserCommand).void }
    def process_command(cmd)
      case cmd
      when UserCommand::DisplayAudibleLibrary then load_audible_library
      when UserCommand::DisplayAudibleUserProfile then load_audible_user_profile
      when UserCommand::DisplayStorygraphLibrary then load_storygraph_library
      when UserCommand::MarkFinishedBooks then mark_finished_books
      when UserCommand::Quit then quit
      else
        T.absurd(cmd)
      end
    end

    sig { void }
    def load_audible_library
      puts audible_library
    end

    sig { returns Audible::Library }
    def audible_library
      @audible_library ||= Audible::Library.load_with_finish_times(client: audible_client,
        options: options, db_client: db_client)
    end

    sig { void }
    def load_storygraph_library
      puts storygraph_library
    end

    sig { returns Storygraph::Library }
    def storygraph_library
      @storygraph_library ||= Storygraph::Library.load(client: storygraph_client,
        db_client: db_client, options: options)
    end

    sig { void }
    def load_audible_user_profile
      puts "#{Util::INFO_EMOJI} Getting Audible user profile..."
      user_profile = audible_client.get_user_profile
      puts user_profile.to_s(indent_level: 1)
    end

    sig { void }
    def mark_finished_books
      Storygraph::MarkFinishedFlow.run(
        finish_dates_by_isbn: audible_library.finish_dates_by_isbn,
        library: storygraph_library,
        client: storygraph_client,
      )
    end

    sig { void }
    def quit
      puts "Goodbye!"
      exit 0
    end

    sig { returns Audible::Client }
    def audible_client
      @audible_client ||= Audible::Client.new(auth: audible_auth, options: options,
        credentials_db: db_client.credentials)
    end

    sig { returns Audible::Auth }
    def audible_auth
      return @audible_auth if @audible_auth
      maybe_auth = GoodAudibleStorySync::Audible::AuthFlow.run(db_client: db_client)
      exit 1 if maybe_auth.nil?
      @audible_auth = maybe_auth
    end

    sig { returns Storygraph::Client }
    def storygraph_client
      @storygraph_client ||= Storygraph::Client.new(auth: storygraph_auth)
    end

    sig { returns Storygraph::Auth }
    def storygraph_auth
      return @storygraph_auth if @storygraph_auth
      maybe_auth = Storygraph::AuthFlow.run(db_client: db_client)
      exit 1 if maybe_auth.nil?
      @storygraph_auth = maybe_auth
    end

    sig { returns Database::Client }
    def db_client
      @db_client ||= Database::Client.load(options.database_file, cipher: cipher)
    end

    sig { returns Options }
    def options
      @options ||= Options.parse(script_name: @script_name, cipher: cipher)
    end

    sig { returns Util::Cipher }
    def cipher
      @cipher ||= Util::Cipher.new
    end
  end
end

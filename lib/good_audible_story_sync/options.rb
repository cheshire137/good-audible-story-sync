# frozen_string_literal: true
# typed: true

require "optparse"

module GoodAudibleStorySync
  class Options
    extend T::Sig

    DEFAULT_CREDENTIALS_FILE = "credentials.txt"
    DEFAULT_LIBRARY_FILE = "audible_library.json"

    # sig { params(script_name: String, argv: Array).returns(Options) }
    def self.parse(script_name:, argv: ARGV)
      puts "Parsing options..."
      new(script_name: script_name, argv: argv).parse
    end

    # sig { params(script_name: String, argv: Array).void }
    def initialize(script_name:, argv: ARGV)
      @options = {}
      @argv = argv
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{script_name} [options]"
        opts.on(
          "-c CREDENTIALS_FILE",
          "--credentials-file",
          String,
          "Path to file that will store encrypted credentials. Defaults to " \
            "#{DEFAULT_CREDENTIALS_FILE}.",
        )
        opts.on(
          "-l LIBRARY_FILE",
          "--library-file",
          String,
          "Path to file that will store info about items in your Audible library. Defaults to " \
            "#{DEFAULT_LIBRARY_FILE}.",
        )
      end

      # sig { returns Options }
      def parse
        @option_parser.parse!(@argv, into: @options)

        if credentials_file == DEFAULT_CREDENTIALS_FILE
          puts "Using default credentials file"
        else
          puts "Using credentials file #{credentials_file}"
        end

        if library_file == DEFAULT_LIBRARY_FILE
          puts "Using default library file"
        else
          puts "Using library file #{library_file}"
        end

        self
      end

      # sig { returns Util::EncryptedJsonFile }
      def credentials_file
        return @credentials_file if @credentials_file
        path = @options[:"credentials-file"] || DEFAULT_CREDENTIALS_FILE
        @credentials_file = Util::EncryptedJsonFile.new(path: path)
      end

      # sig { returns String }
      def library_file
        @library_file ||= @options[:"library-file"] || DEFAULT_LIBRARY_FILE
      end
    end
  end
end

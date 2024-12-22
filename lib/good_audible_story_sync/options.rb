# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "optparse"

module GoodAudibleStorySync
  class Options
    extend T::Sig

    EMOJI_PREFIX = "⚙️"
    DEFAULT_CREDENTIALS_FILE = "credentials.txt"
    DEFAULT_LIBRARY_FILE = "audible_library.json"
    DEFAULT_EXPIRATION_DAYS = 1

    # sig { params(script_name: String, argv: Array).returns(Options) }
    def self.parse(script_name:, argv: ARGV)
      puts "#{EMOJI_PREFIX} Parsing options..."
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
        opts.on(
          "-e EXPIRATION_DAYS",
          "--expiration-days",
          Integer,
          "Max number of days to use cached data, such as Audible library, before " \
            "refreshing. Defaults to #{DEFAULT_EXPIRATION_DAYS}.",
        )
      end

      # sig { returns Options }
      def parse
        @option_parser.parse!(@argv, into: @options)

        if credentials_file == DEFAULT_CREDENTIALS_FILE
          puts "#{Util::TAB}Using default credentials file"
        else
          puts "#{Util::TAB}Using credentials file #{credentials_file}"
        end

        if library_file == DEFAULT_LIBRARY_FILE
          puts "#{Util::TAB}Using default library file"
        else
          puts "#{Util::TAB}Using library file #{library_file}"
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

      # sig { returns Integer }
      def expiration_days
        @expiration_days ||= @options[:"expiration-days"] || DEFAULT_EXPIRATION_DAYS
      end

      # sig { returns Time }
      def refresh_cutoff_time
        Time.now - (expiration_days * 86400)
      end
    end
  end
end

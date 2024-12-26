# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "optparse"

module GoodAudibleStorySync
  class Options
    extend T::Sig

    EMOJI_PREFIX = "⚙️"
    DEFAULT_EXPIRATION_DAYS = 1

    # sig { params(script_name: String, cipher: T.nilable(Util::Cipher), argv: Array).returns(Options) }
    def self.parse(script_name:, cipher: nil, argv: ARGV)
      puts "#{EMOJI_PREFIX} Parsing options..."
      new(script_name: script_name, cipher: cipher, argv: argv).parse
    end

    # sig { params(script_name: String, cipher: T.nilable(Util::Cipher), argv: Array).void }
    def initialize(script_name:, cipher: nil, argv: ARGV)
      @options = {}
      @argv = argv
      @cipher = cipher || Util::Cipher.new
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{script_name} [options]"
        opts.on(
          "-d DATABASE_FILE",
          "--database-file",
          String,
          "Path to Sqlite database file. Defaults to #{Database::Client::DEFAULT_DATABASE_FILE}.",
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
        self
      end

      # sig { returns String }
      def database_file
        @database_file ||= @options[:"database-file"] || Database::Client::DEFAULT_DATABASE_FILE
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

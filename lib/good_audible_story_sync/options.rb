# frozen_string_literal: true

require "optparse"

module GoodAudibleStorySync
  class Options
    DEFAULT_CREDENTIALS_FILE = "credentials.txt"

    def self.parse(script_name:, argv: ARGV)
      puts "Parsing options..."
      new(script_name: script_name, argv: argv).parse
    end

    def initialize(script_name:, argv: ARGV)
      @options = {}
      @argv = argv
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{script_name} [options]"
        opts.on(
          "-c CREDENTIALS_FILE",
          "--credentials-file",
          String,
          "Path to file that will store encrypted Audible credentials. Defaults to " \
            "#{DEFAULT_CREDENTIALS_FILE}.",
        )
      end

      def parse
        @option_parser.parse!(@argv, into: @options)
        unless credentials_file == DEFAULT_CREDENTIALS_FILE
          puts "Using credentials file #{credentials_file}"
        end
        self
      end

      def credentials_file
        @credentials_file ||= @options[:"credentials-file"] || DEFAULT_CREDENTIALS_FILE
      end
    end
  end
end

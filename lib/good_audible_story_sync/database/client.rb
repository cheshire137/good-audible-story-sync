# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Client
      extend T::Sig

      sig { params(options: Options).void }
      def initialize(options:)
        @db = SQLite3::Database.new(options.database_file)
        @credentials = Credentials.new(db: @db)
        @audible_book = AudibleBook.new(db: @db)
        @storygraph_book = StorygraphBook.new(db: @db)
      end

      sig { void }
      def create_tables
        puts "#{Util::INFO_EMOJI} Creating database tables..."
        @audible_book.create_table
        @storygraph_book.create_table
        @credentials.create_table
      end
    end
  end
end

# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Client
      extend T::Sig

      sig { returns SQLite3::Database }
      attr_reader :db

      sig { returns Util::Cipher }
      attr_reader :cipher

      sig { params(options: Options, cipher: Util::Cipher).void }
      def initialize(options:, cipher:)
        @db = SQLite3::Database.new(options.database_file)
        @cipher = cipher
        @credentials = Credentials.new(db_client: self)
        @audible_books = AudibleBooks.new(db: @db)
        @storygraph_books = StorygraphBooks.new(db: @db)
      end

      sig { void }
      def create_tables
        puts "#{Util::INFO_EMOJI} Creating database tables..."
        @audible_books.create_table
        @storygraph_books.create_table
        @credentials.create_table
      end
    end
  end
end

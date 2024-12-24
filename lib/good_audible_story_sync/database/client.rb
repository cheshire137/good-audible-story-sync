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

      sig { returns Credentials }
      attr_reader :credentials

      sig { returns AudibleBooks }
      attr_reader :audible_books

      sig { returns StorygraphBooks }
      attr_reader :storygraph_books

      sig { params(db_file: String, cipher: T.nilable(Util::Cipher)).void }
      def initialize(db_file:, cipher: nil)
        @db = SQLite3::Database.new(db_file)
        @cipher = cipher || Util::Cipher.new
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

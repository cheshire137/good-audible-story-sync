# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Client
      extend T::Sig

      DEFAULT_DATABASE_FILE = "good_audible_story_sync.db"

      sig { params(db_file: String, cipher: T.nilable(Util::Cipher)).returns(Client) }
      def self.load(db_file = DEFAULT_DATABASE_FILE, cipher: nil)
        client = new(db_file: db_file, cipher: cipher)
        client.create_tables
        client
      end

      sig do
        params(db: SQLite3::Database, table_name: String, column_name: String).returns(T::Boolean)
      end
      def self.column_exists?(db:, table_name:, column_name:)
        result = db.get_first_value("SELECT COUNT(*) FROM pragma_table_info(?) WHERE name = ?",
          table_name, column_name)
        result == 1
      end

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

      sig { returns SyncTimes }
      attr_reader :sync_times

      sig { params(db_file: String, cipher: T.nilable(Util::Cipher)).void }
      def initialize(db_file: DEFAULT_DATABASE_FILE, cipher: nil)
        @db = SQLite3::Database.new(db_file)
        @db.results_as_hash = true
        @cipher = cipher || Util::Cipher.new
        @credentials = Credentials.new(db_client: self)
        @audible_books = AudibleBooks.new(db: @db)
        @storygraph_books = StorygraphBooks.new(db: @db)
        @sync_times = SyncTimes.new(db: @db)
      end

      sig { void }
      def create_tables
        @audible_books.create_table
        @storygraph_books.create_table
        @credentials.create_table
        @sync_times.create_table
      end
    end
  end
end

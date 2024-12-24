# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class StorygraphBook
      extend T::Sig

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table storygraph_books exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS storygraph_books (
            id TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            finished_on TEXT
          );
        SQL
      end
    end
  end
end

# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class AudibleBook
      extend T::Sig

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table audible_books exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS audible_books (
            isbn TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            narrator TEXT,
            finished_at TEXT
          );
        SQL
      end
    end
  end
end

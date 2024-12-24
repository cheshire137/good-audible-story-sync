# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Credentials
      extend T::Sig

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table credentials exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS credentials (
            key TEXT PRIMARY KEY,
            value BLOB NOT NULL
          );
        SQL
      end
    end
  end
end

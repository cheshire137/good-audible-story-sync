# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Database
    class SyncTimes
      extend T::Sig

      TABLE_NAME = "sync_times"

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { params(key: String).returns(T.nilable(DateTime)) }
      def find(key)
        puts "#{Util::INFO_EMOJI} Checking when #{key} was last synced..."
        timestamp_str = @db.get_first_value("SELECT timestamp FROM #{TABLE_NAME} WHERE key = ?", key)
        return unless timestamp_str

        DateTime.parse(timestamp_str)
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table #{TABLE_NAME} exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
            key TEXT PRIMARY KEY,
            timestamp TEXT
          );
        SQL
      end

      sig { params(key: String, timestamp: T.nilable(DateTime)).void }
      def upsert(key:, timestamp:)
        puts "#{Util::INFO_EMOJI} Saving sync time #{key}..."
        values = [key, timestamp&.iso8601]
        @db.execute("INSERT INTO #{TABLE_NAME} (key, timestamp) " \
          "VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET timestamp=excluded.timestamp", values)
      end
    end
  end
end

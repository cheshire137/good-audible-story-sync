# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class StorygraphBooks
      extend T::Sig

      TABLE_NAME = "storygraph_books"

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table #{TABLE_NAME} exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
            id TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            finished_on TEXT
          );
        SQL
      end

      sig do
        params(
          id: String,
          title: T.nilable(String),
          author: T.nilable(String),
          finished_on: T.nilable(T.any(String, Date))
        ).void
      end
      def upsert(id:, title:, author:, finished_on:)
        puts "#{Util::INFO_EMOJI} Saving Storygraph book #{id}..."
        values = [id, title, author, finished_on]
        @db.execute("INSERT INTO #{TABLE_NAME} (id, title, author, finished_on) " \
          "VALUES (?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET title=excluded.title, " \
          "author=excluded.author, finished_on=excluded.finished_on", values)
      end
    end
  end
end

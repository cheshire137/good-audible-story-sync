# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class AudibleBooks
      extend T::Sig

      TABLE_NAME = "audible_books"

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table #{TABLE_NAME} exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
            isbn TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            narrator TEXT,
            finished_at TEXT
          );
        SQL
      end

      def find_all
        @db.execute("SELECT * FROM #{TABLE_NAME}")
      end

      sig do
        params(
          isbn: String,
          title: T.nilable(String),
          author: T.nilable(String),
          narrator: T.nilable(String),
          finished_at: T.nilable(T.any(String, DateTime, Time, Date))
        ).void
      end
      def upsert(isbn:, title:, author:, narrator:, finished_at:)
        puts "#{Util::INFO_EMOJI} Saving Audible book #{isbn}..."
        finished_at_str = if finished_at.respond_to?(:iso8601)
          T.unsafe(finished_at).iso8601
        else
          finished_at
        end
        values = [isbn, title, author, narrator, finished_at_str]
        @db.execute("INSERT INTO #{TABLE_NAME} (isbn, title, author, narrator, finished_at) " \
          "VALUES (?, ?, ?, ?, ?) ON CONFLICT(isbn) DO UPDATE SET title=excluded.title, " \
          "author=excluded.author, narrator=excluded.narrator, " \
          "finished_at=excluded.finished_at", values)
      end
    end
  end
end

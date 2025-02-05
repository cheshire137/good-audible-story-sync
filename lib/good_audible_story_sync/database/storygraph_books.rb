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
        unless Client.column_exists?(db: @db, table_name: TABLE_NAME, column_name: "isbn")
          puts "#{Util::INFO_EMOJI} Adding isbn column to #{TABLE_NAME}..."
          @db.execute("ALTER TABLE #{TABLE_NAME} ADD COLUMN isbn TEXT")
        end
        unless Client.column_exists?(db: @db, table_name: TABLE_NAME, column_name: "status")
          puts "#{Util::INFO_EMOJI} Adding status column to #{TABLE_NAME}..."
          @db.execute("ALTER TABLE #{TABLE_NAME} ADD COLUMN status TEXT")
        end
      end

      sig { returns T::Array[T::Hash[String, T.untyped]] }
      def find_all
        @db.execute("SELECT id, title, author, finished_on, status " \
          "FROM #{TABLE_NAME} ORDER BY finished_on DESC, title ASC, id ASC")
      end

      sig { params(id: String).void }
      def delete(id)
        puts "#{Util::INFO_EMOJI} Removing cached Storygraph book #{id}..."
        @db.execute("DELETE FROM #{TABLE_NAME} WHERE id = ?", id)
      end

      sig do
        params(
          id: String,
          title: T.nilable(String),
          author: T.nilable(String),
          finished_on: T.nilable(T.any(String, Date)),
          isbn: T.nilable(String),
          status: T.nilable(String)
        ).void
      end
      def upsert(id:, title:, author:, finished_on:, isbn:, status:)
        puts "#{Util::INFO_EMOJI} Saving Storygraph book #{id}..."
        finished_on_str = if finished_on.respond_to?(:iso8601)
          T.unsafe(finished_on).iso8601
        else
          finished_on
        end
        values = [id, title, author, finished_on_str, isbn, status]
        @db.execute("INSERT INTO #{TABLE_NAME} (id, title, author, finished_on, isbn, status) " \
          "VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET title=excluded.title, " \
          "author=excluded.author, finished_on=excluded.finished_on, isbn=excluded.isbn, " \
          "status=excluded.status", values)
      end
    end
  end
end

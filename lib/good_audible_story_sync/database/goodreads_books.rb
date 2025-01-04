# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class GoodreadsBooks
      extend T::Sig

      TABLE_NAME = "goodreads_books"

      sig { params(db: SQLite3::Database).void }
      def initialize(db:)
        @db = db
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table #{TABLE_NAME} exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
            slug TEXT PRIMARY KEY,
            title TEXT,
            author TEXT,
            status TEXT,
            isbn TEXT
          );
        SQL
      end

      sig { returns T::Array[T::Hash[String, T.untyped]] }
      def find_all
        @db.execute("SELECT slug, title, author, status, isbn " \
          "FROM #{TABLE_NAME} ORDER BY title ASC, slug ASC")
      end

      sig { params(slug: String).void }
      def delete(slug)
        puts "#{Util::INFO_EMOJI} Removing cached Goodreads book #{slug}..."
        @db.execute("DELETE FROM #{TABLE_NAME} WHERE slug = ?", slug)
      end

      sig do
        params(
          slug: String,
          title: T.nilable(String),
          author: T.nilable(String),
          isbn: T.nilable(String),
          status: T.nilable(String)
        ).void
      end
      def upsert(slug:, title:, author:, isbn:, status:)
        puts "#{Util::INFO_EMOJI} Saving Goodreads book #{slug}..."
        values = [slug, title, author, isbn, status]
        @db.execute("INSERT INTO #{TABLE_NAME} (slug, title, author, isbn, status) " \
          "VALUES (?, ?, ?, ?, ?) ON CONFLICT(slug) DO UPDATE SET title=excluded.title, " \
          "author=excluded.author, isbn=excluded.isbn, status=excluded.status", values)
      end
    end
  end
end

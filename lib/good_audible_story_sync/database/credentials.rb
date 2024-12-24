# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Credentials
      extend T::Sig

      TABLE_NAME = "credentials"

      sig { params(db_client: Database::Client).void }
      def initialize(db_client:)
        @db = T.let(db_client.db, SQLite3::Database)
        @cipher = T.let(db_client.cipher, Util::Cipher)
      end

      sig { params(key: String).returns(T.nilable(T::Hash[String, T.untyped])) }
      def find(key:)
        puts "#{Util::INFO_EMOJI} Looking for '#{key}' credentials..."
        encrypted_value = @db.get_first_value("SELECT value FROM #{TABLE_NAME} WHERE key = ?", key)
        return unless encrypted_value

        value = @cipher.decrypt(encrypted_value)
        JSON.parse(value)
      end

      sig { void }
      def create_table
        puts "#{Util::INFO_EMOJI} Ensuring table #{TABLE_NAME} exists..."
        @db.execute <<~SQL
          CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
            key TEXT PRIMARY KEY,
            value BLOB NOT NULL
          );
        SQL
      end

      sig { params(key: String, value: T::Hash[String, T.untyped]).void }
      def upsert(key:, value:)
        encrypted_value = @cipher.encrypt(value.to_json)
        values = [key, encrypted_value]
        puts "#{Util::INFO_EMOJI} Saving '#{key}' credentials..."
        @db.execute("INSERT INTO #{TABLE_NAME} (key, value) VALUES (?, ?) " \
          "ON CONFLICT(key) DO UPDATE SET value=excluded.value", values)
      end
    end
  end
end

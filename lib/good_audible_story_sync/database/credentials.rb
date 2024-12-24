# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Database
    class Credentials
      extend T::Sig

      sig { params(db_client: Database::Client).void }
      def initialize(db_client:)
        @db = T.let(db_client.db, SQLite3::Database)
        @cipher = T.let(db_client.cipher, Util::Cipher)
      end

      sig { params(key: String).returns(T.nilable(T::Hash[String, T.untyped])) }
      def find(key:)
        encrypted_value = @db.get_first_value("SELECT value FROM credentials WHERE key = ?", key)
        return unless encrypted_value

        value = @cipher.decrypt(encrypted_value)
        JSON.parse(value)
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

      sig { params(key: String, value: T::Hash[String, T.untyped]).void }
      def upsert(key:, value:)
        encrypted_value = @cipher.encrypt(value.to_json)
        values = [key, encrypted_value]
        puts "#{Util::INFO_EMOJI} Saving '#{key}' credentials..."
        @db.execute("INSERT INTO credentials (key, value) VALUES (?, ?) " \
          "ON CONFLICT(key) DO UPDATE SET value=excluded.value", values)
      end

      sig { params(encrypted_file: Util::EncryptedJsonFile).returns(T::Boolean) }
      def upsert_from_file(encrypted_file)
        return false unless encrypted_file.exists?

        data = encrypted_file.load

        audible_data = (data.key?("audible") ? data["audible"] : data) || {}
        audible_value = audible_data.slice("adp_token", "device_private_key", "access_token",
          "refresh_token", "expires", "website_cookies", "store_authentication_cookie",
          "device_info", "customer_info")
        upsert(key: "audible", value: audible_value)

        storygraph_data = data["storygraph"] || {}
        storygraph_value = storygraph_data.slice("email", "password", "username")
        upsert(key: "storygraph", value: storygraph_value)

        true
      end
    end
  end
end

# frozen_string_literal: true
# typed: true

require_relative "./encrypted_file"

module GoodAudibleStorySync
  module Util
    class EncryptedJsonFile
      extend T::Sig

      sig { returns String }
      attr_reader :path

      sig { params(path: String, cipher: Cipher).void }
      def initialize(path:, cipher:)
        @path = path
        @encrypted_file = EncryptedFile.new(path: path, cipher: cipher)
        @loaded_contents = nil
      end

      sig { returns T::Boolean }
      def exists?
        File.exist?(@path)
      end

      sig { returns T::Hash[String, T.untyped] }
      def load
        @loaded_contents ||= JSON.parse(@encrypted_file.read)
      end

      sig { params(data: T::Hash[String, T.untyped]).returns(Integer) }
      def save(data)
        @loaded_contents = nil
        @encrypted_file.write(JSON.pretty_generate(data))
      end

      sig { params(new_data: T::Hash[String, T.untyped]).returns(Integer) }
      def merge(new_data)
        existing_data = load
        save(existing_data.merge(new_data))
      end

      sig { returns String }
      def to_s
        path
      end
    end
  end
end

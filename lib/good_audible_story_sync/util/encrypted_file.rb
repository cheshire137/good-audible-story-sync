# frozen_string_literal: true
# typed: true

require "lockbox"
require_relative "./keychain"

module GoodAudibleStorySync
  module Util
    class EncryptedFile
      extend T::Sig

      ENCRYPTION_KEY_NAME = "good_audible_story_sync_encryption_key"

      sig { returns String }
      def self.key
        result = Keychain.load(name: ENCRYPTION_KEY_NAME)
        if result.nil? || result.empty?
          puts "No encryption key found in keychain. Generating a new one..."
          result = Lockbox.generate_key
          Keychain.save(name: ENCRYPTION_KEY_NAME, value: result)
        else
          puts "Using GoodAudibleStorySync encryption key from keychain"
        end
        result
      end

      sig { params(path: String).void }
      def initialize(path:)
        @path = path
        @lockbox = Lockbox.new(key: self.class.key)
      end

      sig { params(contents: String).returns(Integer) }
      def write(contents)
        puts "Saving encrypted file #{@path}..."
        File.write(@path, @lockbox.encrypt(contents))
      end

      sig { returns String }
      def read
        puts "Reading encrypted file #{@path}..."
        encrypted_contents = File.read(@path)
        @lockbox.decrypt(encrypted_contents)
      end
    end
  end
end

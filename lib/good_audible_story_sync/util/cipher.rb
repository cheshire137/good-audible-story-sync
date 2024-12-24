# frozen_string_literal: true
# typed: true

require "lockbox"
require_relative "./keychain"

module GoodAudibleStorySync
  module Util
    class Cipher
      extend T::Sig

      ENCRYPTION_KEY_NAME = "good_audible_story_sync_encryption_key"

      sig { returns String }
      def self.key
        result = Keychain.load(name: ENCRYPTION_KEY_NAME)
        if result.nil? || result.empty?
          puts "#{INFO_EMOJI} No encryption key found in keychain. Generating a new one..."
          result = Lockbox.generate_key
          Keychain.save(name: ENCRYPTION_KEY_NAME, value: result)
        else
          puts "#{INFO_EMOJI} Using GoodAudibleStorySync encryption key from keychain"
        end
        result
      end

      sig { void }
      def initialize
        @lockbox = Lockbox.new(key: self.class.key)
      end

      sig { params(contents: String).returns(String) }
      def encrypt(contents)
        @lockbox.encrypt(contents)
      end

      sig { params(value: String).returns(String) }
      def decrypt(value)
        @lockbox.decrypt(value)
      end
    end
  end
end

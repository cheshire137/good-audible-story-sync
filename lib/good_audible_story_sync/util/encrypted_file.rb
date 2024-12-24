# frozen_string_literal: true
# typed: true

require "lockbox"
require_relative "./keychain"

module GoodAudibleStorySync
  module Util
    class EncryptedFile
      extend T::Sig

      sig { params(path: String, cipher: Cipher).void }
      def initialize(path:, cipher:)
        @path = path
        @cipher = cipher
      end

      sig { params(contents: String).returns(Integer) }
      def write(contents)
        puts "#{SAVE_EMOJI} Saving encrypted file #{@path}..."
        File.write(@path, @cipher.encrypt(contents))
      end

      sig { returns String }
      def read
        puts "#{INFO_EMOJI} Reading encrypted file #{@path}..."
        @cipher.decrypt(File.read(@path))
      end
    end
  end
end

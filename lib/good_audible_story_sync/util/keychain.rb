# frozen_string_literal: true
# typed: true
# encoding: utf-8

module GoodAudibleStorySync
  module Util
    class Keychain
      extend T::Sig

      LOCK_EMOJI = "🔐"

      sig { params(name: String, value: String).void }
      def self.save(name:, value:)
        account_name = self.account_name
        puts "#{LOCK_EMOJI} Saving '#{name}' to #{account_name}'s keychain..."
        `security add-generic-password -s '#{name}' -a '#{account_name}' -w '#{value}'`
      end

      sig { params(name: String).returns(T.nilable(String)) }
      def self.load(name:)
        account_name = self.account_name
        puts "#{LOCK_EMOJI} Looking for '#{name}' in #{account_name}'s keychain..."
        `security find-generic-password -w -s '#{name}' -a '#{account_name}'`.strip
      end

      sig { returns String }
      def self.account_name
        `whoami`.strip
      end
    end
  end
end

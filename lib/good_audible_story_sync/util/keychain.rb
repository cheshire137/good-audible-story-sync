# frozen_string_literal: true

module GoodAudibleStorySync
  module Util
    class Keychain
      def self.save(name:, value:)
        account_name = self.account_name
        puts "Saving '#{name}' to #{account_name}'s keychain..."
        `security add-generic-password -s '#{name}' -a '#{account_name}' -w '#{value}'`
      end

      def self.load(name:)
        account_name = self.account_name
        puts "Looking for '#{name}' in #{account_name}'s keychain..."
        `security find-generic-password -w -s '#{name}' -a '#{account_name}'`.strip
      end

      def self.account_name
        `whoami`.strip
      end
    end
  end
end

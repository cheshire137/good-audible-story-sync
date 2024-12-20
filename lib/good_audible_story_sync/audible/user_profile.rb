# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Audible
    class UserProfile
      extend T::Sig

      sig { params(data: Hash).void }
      def initialize(data)
        @data = data
      end

      sig { returns T.nilable(String) }
      def user_id
        @data["user_id"]
      end

      sig { returns T.nilable(String) }
      def name
        @data["name"]
      end

      sig { returns T.nilable(String) }
      def email
        @data["email"]
      end

      sig { params(indent_level: Integer).returns(String) }
      def to_s(indent_level: 0)
        tab = Util::TAB * indent_level
        line1 = "#{tab}Audible user ID: #{user_id}"
        line2 = "#{tab}Name: #{name}"
        line3 = "#{tab}Email: #{email}"
        [line1, line2, line3].join("\n")
      end
    end
  end
end

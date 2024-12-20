# frozen_string_literal: true
# typed: true

require 'mechanize'

module GoodAudibleStorySync
  module Storygraph
    class Auth
      extend T::Sig

      def initialize
        @agent = Mechanize.new
      end

      def login
        page = @agent.get("https://app.thestorygraph.com/users/sign_in")
        pp page
      end
    end
  end
end

# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Util
    extend T::Sig

    sig { params(words: T::Array[String]).returns(String) }
    def self.join_words(words)
      case words.size
      when 0 then ""
      when 1 then T.must(words[0])
      when 2 then words.join(" and ")
      else
        head = T.must(words[0...-1]).join(", ")
        tail = T.must(words[-1])
        "#{head}, and #{tail}"
      end
    end
  end
end

require_relative "util/encrypted_file"
require_relative "util/keychain"

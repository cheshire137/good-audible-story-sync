# frozen_string_literal: true
# typed: true
# encoding: utf-8

module GoodAudibleStorySync
  module Util
    extend T::Sig

    TAB = "  "
    INFO_EMOJI = "ℹ️"
    ERROR_EMOJI = "❌"
    SAVE_EMOJI = "💾"
    SUCCESS_EMOJI = "🟢"
    DONE_EMOJI = "✅"
    NEWLINE_EMOJI = "⮑"
    WARNING_EMOJI = "🟡"

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

    sig { params(words_str: String).returns(T::Array[String]) }
    def self.split_words(words_str)
      words_str.split(/, | and/).map { |word| word.strip.sub(/^and /, "") }
    end

    sig { params(timestamp: T.any(DateTime, Time)).returns(String) }
    def self.pretty_time(timestamp)
      # e.g., "Fri November 29, 2024 at 2:47am"
      timestamp.strftime("%a %B %-d, %Y at %-l:%M%P")
    end

    sig { params(date: T.any(DateTime, Time, Date)).returns(String) }
    def self.pretty_date(date)
      # e.g., "Fri November 29, 2024"
      date.strftime("%a %B %-d, %Y")
    end
  end
end

require_relative "util/cipher"
require_relative "util/keychain"

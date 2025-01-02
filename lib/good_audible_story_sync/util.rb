# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "rainbow"

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

    sig { params(str: T.nilable(String)).returns(T.nilable(String)) }
    def self.squish(str)
      return unless str
      str.gsub(/[[:space:]]+/, " ").strip
    end

    sig { params(str: String).returns(T::Boolean) }
    def self.integer?(str)
      str.to_i.to_s == str
    end

    sig { params(str: String).returns(T::Boolean) }
    def self.isbn?(str)
      idx = str =~ /^(?=(?:\D*\d){10}(?:(?:\D*\d){3})?$)[\d-]+$/
      idx == 0
    end

    sig { params(option: String, description: String).void }
    def self.print_option(option, description)
      desc_words = description.split(" ")
      word_to_highlight = desc_words.detect { |word| word.downcase.start_with?(option) }
      highlighted_word_index = desc_words.index(word_to_highlight)
      highlighted_option = Rainbow(option).green
      highlighted_word = if word_to_highlight
        head = word_to_highlight.slice(0)
        tail = word_to_highlight.slice(1..)
        highlighted_head = Rainbow(head).green
        "#{highlighted_head}#{tail}"
      end
      highlighted_description = if highlighted_word_index
        head = (desc_words.slice(0, highlighted_word_index) || []).join(" ")
        tail = (desc_words.slice(highlighted_word_index + 1..) || []).join(" ")
        [head, highlighted_word, tail].compact.join(" ").strip
      else
        description
      end
      puts "#{highlighted_option}) #{highlighted_description}"
    end
  end
end

require_relative "util/cipher"
require_relative "util/keychain"

# frozen_string_literal: true
# encoding: utf-8
# typed: true

require "date"
require "rainbow"

module GoodAudibleStorySync
  module Audible
    class LibraryItem
      extend T::Sig

      sig { params(finished_at: T.nilable(DateTime)).void }
      attr_writer :finished_at

      sig { returns Hash }
      attr_reader :data

      sig { params(data: Hash).void }
      def initialize(data)
        @data = data
      end

      sig { returns T.nilable(DateTime) }
      def finished_at
        return @finished_at if defined?(@finished_at)
        finished_at_str = @data["finished_at"]
        if finished_at_str.nil? && @data.dig("listening_status", "is_finished")
          finished_at_str = @data.dig("listening_status", "finished_at_timestamp")
        end
        @finished_at = finished_at_str ? DateTime.parse(finished_at_str) : nil
      rescue Date::Error
        nil
      end

      sig { returns T.nilable(DateTime) }
      def last_listened_at
        return @last_listened_at if defined?(@last_listened_at)
        date_str = @data.dig("listening_status", "finished_at_timestamp")
        @last_listened_at = date_str ? DateTime.parse(date_str) : nil
      rescue Date::Error
        nil
      end

      sig { returns T.nilable(DateTime) }
      def added_to_library_at
        return @added_to_library_at if defined?(@added_to_library_at)
        date_added_str = @data.dig("library_status", "date_added")
        @added_to_library_at = date_added_str ? DateTime.parse(date_added_str) : purchase_date
      rescue Date::Error
        nil
      end

      sig { returns T.nilable(String) }
      def asin
        @data["asin"]
      end

      sig { returns T::Array[String] }
      def narrators
        return @narrators if @narrators
        narrator_str = T.let(@data["narrator"], T.nilable(String))
        if narrator_str # data from database
          @narrators = Util.split_words(narrator_str)
        else # data from Audible API
          hashes = @data["narrators"] || []
          @narrators = hashes.map { |hash| hash["name"] }
        end
      end

      sig { returns T::Array[String] }
      def authors
        return @authors if @authors
        author_str = T.let(@data["author"], T.nilable(String))
        if author_str # data from database
          @authors = Util.split_words(author_str)
        else # data from Audible API
          hashes = @data["authors"] || []
          @authors = hashes.map { |hash| hash["name"] }
        end
      end

      sig { params(books_db: Database::AudibleBooks).returns(T::Boolean) }
      def save_to_database(books_db)
        isbn = self.isbn
        return false unless isbn

        books_db.upsert(isbn: isbn, title: title, author: Util.join_words(authors),
          narrator: Util.join_words(narrators), finished_at: finished_at,
          percent_complete: percent_complete)

        true
      end

      sig { params(stylize: T::Boolean).returns(T.nilable(String)) }
      def title(stylize: false)
        value = @data["title"]
        return value unless stylize && value
        Rainbow(value).underline
      end

      sig { returns Integer }
      def percent_complete
        return @percent_complete if @percent_complete
        pct = T.let(
          @data["percent_complete"] || @data.dig("listening_status", "percent_complete"),
          T.nilable(T.any(Float, Integer))
        )
        @percent_complete = pct.nil? ? 0 : pct.round
      end

      sig { returns T::Boolean }
      def finished?
        return true if finished_at || percent_complete == 100
        is_finished = @data.dig("listening_status", "is_finished")
        !!is_finished
      end

      sig { returns T::Boolean }
      def started?
        return @is_started if defined?(@is_started)
        @is_started = percent_complete > 0 || !@data["listening_status"].nil?
      end

      sig { returns T.nilable(String) }
      def isbn
        @data["isbn"]
      end

      sig { returns T.nilable(Integer) }
      def time_remaining_in_seconds
        @data.dig("listening_status", "time_remaining_seconds")
      end

      sig { params(indent_level: Integer, stylize: T::Boolean).returns(String) }
      def title_and_authors(indent_level: 0, stylize: false)
        "#{Util::TAB * indent_level}#{title(stylize: stylize)} by #{Util.join_words(authors)}"
      end

      sig { params(indent_level: Integer, stylize: T::Boolean).returns(String) }
      def narrator_summary(indent_level: 0, stylize: false)
        value = "Narrated by #{Util.join_words(narrators)}"
        value = Rainbow(value).italic if stylize
        "#{Util::TAB * indent_level}#{Util::NEWLINE_EMOJI} #{value}"
      end

      sig { params(stylize: T::Boolean).returns(String) }
      def finish_status(stylize: false)
        finished_at = self.finished_at
        if finished_at
          value = "Finished #{Util.pretty_time(finished_at)}"
          value = Rainbow(value).green if stylize
          value
        elsif finished?
          value = "Finished"
          value = Rainbow(value).green if stylize
          value
        elsif started?
          value = "#{percent_complete}% complete"
          value = Rainbow(value).yellow if stylize
          value
        else
          value = "Not started"
          value = Rainbow(value).white if stylize
          value
        end
      end

      sig { returns String }
      def inspect
        @data.inspect
      end

      sig { params(indent_level: Integer, stylize: T::Boolean).returns(String) }
      def to_s(indent_level: 0, stylize: false)
        line1 = "#{title_and_authors(indent_level: indent_level, stylize: stylize)} — " \
          "#{finish_status(stylize: stylize)}"
        line2 = narrator_summary(indent_level: indent_level + 1, stylize: stylize)
        [line1, line2].join("\n")
      end

      sig { returns T.nilable(String) }
      def search_query
        return unless title
        [title, Util.join_words(authors)].compact.join(" ")
      end

      sig { returns T.nilable(DateTime) }
      def purchase_date
        return @purchase_date if defined?(@purchase_date)
        purchase_date_str = @data["purchase_date"]
        @purchase_date = purchase_date_str ? DateTime.parse(purchase_date_str) : nil
      rescue Date::Error
        nil
      end

      # Public: Get a rough idea of when the item would have been listened to. The start date will be too broad, as
      # it's just when the item was added to the library and not necessarily when it was begun.
      sig { returns T::Range[T.nilable(DateTime)] }
      def listening_time_range
        @listening_time_range ||= Range.new(added_to_library_at, last_listened_at)
      end

      sig { returns T::Hash[Symbol, T.untyped] }
      def to_h
        @to_h ||= @data.reject { |k, v| v.nil? }.map { |k, v| [k.to_sym, v] }.to_h.merge(
          finished_at: finished_at&.iso8601,
          purchase_date: purchase_date&.iso8601,
        )
      end
    end
  end
end

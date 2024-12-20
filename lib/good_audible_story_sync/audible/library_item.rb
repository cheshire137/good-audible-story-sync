# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Audible
    class LibraryItem
      extend T::Sig

      sig { params(data: Hash).void }
      def initialize(data)
        @data = data
      end

      sig { returns T.nilable(DateTime) }
      def added_to_library_at
        date_str = @data.dig("library_status", "date_added") || @data["purchase_date"]
        DateTime.parse(date_str) if date_str
      end

      sig { returns T.nilable(String) }
      def asin
        @data["asin"]
      end

      sig { returns T::Array[String] }
      def narrators
        return @narrators if @narrators
        hashes = @data["narrators"] || []
        @narrators = hashes.map { |hash| hash["name"] }
      end

      sig { returns T::Array[String] }
      def authors
        return @authors if @authors
        hashes = @data["authors"] || []
        @authors = hashes.map { |hash| hash["name"] }
      end

      sig { returns T.nilable(String) }
      def title
        @data["title"]
      end

      sig { returns Integer }
      def percent_complete
        pct = T.let(
          @data["percent_complete"] || @data.dig("listening_status", "percent_complete"),
          T.nilable(Float)
        )
        pct.nil? ? 0 : pct.round
      end

      sig { returns T::Boolean }
      def finished?
        is_finished = @data.dig("listening_status", "is_finished")
        return percent_complete == 100 if is_finished.nil?
        is_finished
      end

      sig { returns T::Boolean }
      def started?
        return false if @data["listening_status"].nil?
        percent_complete > 0
      end

      sig { returns T.nilable(String) }
      def isbn
        @data["isbn"]
      end

      sig { returns T.nilable(Integer) }
      def time_remaining_in_seconds
        @data.dig("listening_status", "time_remaining_seconds")
      end

      sig { returns Hash }
      def to_h
        @data
      end
    end
  end
end

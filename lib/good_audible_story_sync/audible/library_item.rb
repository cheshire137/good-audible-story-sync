# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Audible
    class LibraryItem
      extend T::Sig

      sig { params(data: Hash).void }
      def initialize(data)
        @data = data
      end

      sig { returns T.nilable(String) }
      def asin
        @data["asin"]
      end

      sig { returns T::Array[String] }
      def narrators
        hashes = @data["narrators"] || []
        hashes.map { |hash| hash["name"] }
      end

      sig { returns T::Array[String] }
      def authors
        hashes = @data["authors"] || []
        hashes.map { |hash| hash["name"] }
      end

      sig { returns T.nilable(String) }
      def title
        @data["title"]
      end

      sig { returns T.nilable(Integer) }
      def percent_complete
        pct = T.let(
          @data["percent_complete"] || @data.dig("listening_status", "percent_complete"),
          T.nilable(Float)
        )
        pct&.round
      end

      sig { returns T::Boolean }
      def finished?
        is_finished = @data.dig("listening_status", "is_finished")
        return percent_complete == 100 if is_finished.nil?
        is_finished
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

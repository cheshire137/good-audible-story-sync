# frozen_string_literal: true
# encoding: utf-8
# typed: true

require "date"

module GoodAudibleStorySync
  module Audible
    class LibraryItem
      extend T::Sig

      sig { returns T.nilable(DateTime) }
      attr_accessor :finished_at

      sig { params(data: Hash).void }
      def initialize(data)
        @data = data
        @finished_at = data["finished_at"] ? DateTime.parse(data["finished_at"]) : nil
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

      sig { params(db_client: Database::AudibleBooks).returns(T::Boolean) }
      def save_to_database(db_client)
        isbn = self.isbn
        return false unless isbn

        db_client.upsert(isbn: isbn, title: title, author: Util.join_words(authors),
          narrator: Util.join_words(narrators), finished_at: finished_at)

        true
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
        return true if finished_at || percent_complete == 100
        is_finished = @data.dig("listening_status", "is_finished")
        !!is_finished
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

      sig { params(indent_level: Integer).returns(String) }
      def title_and_authors(indent_level: 0)
        "#{Util::TAB * indent_level}#{title} by #{Util.join_words(authors)}"
      end

      sig { params(indent_level: Integer).returns(String) }
      def narrator_summary(indent_level: 0)
        "#{Util::TAB * indent_level}#{Util::NEWLINE_EMOJI} Narrated by #{Util.join_words(narrators)}"
      end

      sig { returns String }
      def finish_status
        finished_at = self.finished_at
        if finished_at
          "Finished #{Util.pretty_time(finished_at)}"
        elsif finished?
          "Finished"
        elsif started?
          "#{percent_complete}% complete"
        else
          "Not started"
        end
      end

      sig { params(indent_level: Integer).returns(String) }
      def to_s(indent_level: 0)
        line1 = "#{title_and_authors(indent_level: indent_level)} — #{finish_status}"
        line2 = narrator_summary(indent_level: indent_level + 1)
        [line1, line2].join("\n")
      end

      sig { returns T.nilable(String) }
      def search_query
        return isbn if isbn
        return unless title
        [title, Util.join_words(authors)].compact.join(" ")
      end

      sig { returns Hash }
      def to_h
        @data.merge(finished_at: finished_at&.iso8601)
      end
    end
  end
end

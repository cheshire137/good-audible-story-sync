# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "date"

module GoodAudibleStorySync
  module Audible
    class Library
      extend T::Sig

      SYNC_TIME_KEY = "audible_library"

      sig do
        params(client: Client, options: Options, db_client: Database::Client).returns(Library)
      end
      def self.load_with_finish_times(client:, options:, db_client:)
        load_finish_times = T.let(false, T::Boolean)
        library_cache_last_modified = db_client.sync_times.find(SYNC_TIME_KEY)&.to_time
        library_is_cached = !library_cache_last_modified.nil?
        should_refresh_library = library_cache_last_modified &&
          library_cache_last_modified > options.refresh_cutoff_time

        if library_is_cached && should_refresh_library
          library = load_from_database(db_client.audible_books)
          load_finish_times = !library.any_finished_time_loaded?
        else
          if library_is_cached
            puts "#{Util::INFO_EMOJI} Audible library cache has not been updated " \
              "since #{Util.pretty_time(library_cache_last_modified)}, updating..."
          end
          library = client.get_all_library_pages
          load_finish_times = true
        end

        if load_finish_times
          finish_times_by_asin = client.get_finish_times_by_asin
          library.populate_finish_times(finish_times_by_asin)
          library.save_to_database(db_client)
        end

        library
      end

      sig { params(books_db: Database::AudibleBooks).returns(Library) }
      def self.load_from_database(books_db)
        library = new
        library.load_from_database(books_db)
        library
      end

      sig { returns T::Array[LibraryItem] }
      attr_reader :items

      sig { params(items: T::Array[LibraryItem]).void }
      def initialize(items: [])
        @items = items
        @loaded_from_database = T.let(false, T::Boolean)
      end

      sig { returns Integer }
      def total_items
        items.size
      end

      sig { params(db_client: Database::Client).returns(Integer) }
      def save_to_database(db_client)
        puts "#{Util::SAVE_EMOJI} Caching Audible library in database..."
        total_saved = 0
        books_db = db_client.audible_books
        items.each do |library_item|
          isbn = library_item.isbn
          if isbn
            success = library_item.save_to_database(books_db)
            total_saved += 1 if success
          else
            puts "#{Util::TAB}#{Util::WARNING_EMOJI} Skipping book with no ISBN: #{library_item}"
          end
        end
        db_client.sync_times.touch(SYNC_TIME_KEY)
        total_saved
      end

      sig { returns T::Boolean }
      def loaded_from_database?
        @loaded_from_database
      end

      sig { params(books_db: Database::AudibleBooks).returns(T::Boolean) }
      def load_from_database(books_db)
        puts "#{Util::INFO_EMOJI} Loading cached Audible library..."

        rows = books_db.find_all
        @items = rows.map { |row| LibraryItem.new(row) }

        @loaded_from_database = true
      end

      sig { returns T::Boolean }
      def any_finished_time_loaded?
        items.any? { |library_item| !library_item.finished_at.nil? }
      end

      sig { params(finish_times_by_asin: T::Hash[String, DateTime]).void }
      def populate_finish_times(finish_times_by_asin)
        items.each do |library_item|
          asin = library_item.asin
          library_item.finished_at = if asin
            finish_times_by_asin[asin]
          end
        end

        @finished_items = @unfinished_items = nil # force recalculation

        if total_finished < 1
          puts "#{Util::INFO_EMOJI} No books in Audible library have been finished."
        else
          puts "#{Util::INFO_EMOJI} Loaded finished status for #{total_finished} " \
            "#{finished_item_units} from Audible library."
        end
      end

      sig { returns T::Array[LibraryItem] }
      def finished_items
        calculate_finished_unfinished_items
        @finished_items
      end

      sig { returns T::Array[LibraryItem] }
      def started_items
        calculate_started_not_started_items
        @started_items
      end

      sig { returns T::Array[LibraryItem] }
      def not_started_items
        calculate_started_not_started_items
        @not_started_items
      end

      sig { returns T::Array[LibraryItem] }
      def unfinished_items
        calculate_finished_unfinished_items
        @unfinished_items
      end

      sig { returns Integer }
      def total_finished
        @total_finished ||= finished_items.size
      end

      sig { returns Integer }
      def finished_percent
        @finished_percent ||= (total_finished.to_f / total_items * 100).round
      end

      sig { returns Integer }
      def total_started
        @total_started ||= started_items.size
      end

      sig { returns Integer }
      def started_percent
        @started_percent ||= (total_started.to_f / total_items * 100).round
      end

      sig { returns Integer }
      def total_unfinished
        @total_unfinished ||= unfinished_items.size
      end

      sig { returns Integer }
      def unfinished_percent
        @unfinished_percent ||= (total_unfinished.to_f / total_items * 100).round
      end

      sig { returns Integer }
      def total_not_started
        @total_not_started ||= not_started_items.size
      end

      sig { returns Integer }
      def not_started_percent
        @not_started_percent ||= (total_not_started.to_f / total_items * 100).round
      end

      sig { returns String }
      def finished_item_units
        total_finished == 1 ? "book" : "books"
      end

      sig { returns String }
      def item_units
        total_items == 1 ? "book" : "books"
      end

      sig { returns String }
      def started_item_units
        total_started == 1 ? "book" : "books"
      end

      sig { returns String }
      def unfinished_item_units
        total_unfinished == 1 ? "book" : "books"
      end

      sig { returns String }
      def not_started_item_units
        total_not_started == 1 ? "book" : "books"
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(items.map(&:to_h))
      end

      sig { params(limit: Integer).returns(String) }
      def finished_items_summary(limit: 5)
        lines = T.let([
          "☑ #{total_finished} #{finished_item_units} " \
            "(#{finished_percent}%) in Audible library have been finished:",
        ], T::Array[String])
        lines.concat(finished_items.take(limit).map { |item| item.to_s(indent_level: 1) })
        lines << "#{Util::TAB}..." if total_finished > limit
        lines << ""
        lines.join("\n")
      end

      sig { params(limit: Integer).returns(T.nilable(String)) }
      def not_started_items_summary(limit: 5)
        return if total_not_started < 1

        lines = T.let([
          "🌱 #{total_not_started} #{not_started_item_units} (#{not_started_percent}%) " \
            "in Audible library have not been started:",
        ], T::Array[String])
        lines.concat(not_started_items.take(limit).map { |item| item.to_s(indent_level: 1) })
        lines << "#{Util::TAB}..." if total_not_started > limit
        lines << ""
        lines.join("\n")
      end

      sig { params(limit: Integer).returns(T.nilable(String)) }
      def started_items_summary(limit: 5)
        return if total_started < 1

        lines = T.let([
          "🔜 #{total_started} #{started_item_units} (#{started_percent}%) in Audible " \
            "library are in progress:",
        ], T::Array[String])
        lines.concat(started_items.take(limit).map { |item| item.to_s(indent_level: 1) })
        lines << "#{Util::TAB}..." if total_started > limit
        lines << ""
        lines.join("\n")
      end

      sig { params(limit: Integer).returns(String) }
      def to_s(limit: 5)
        [
          "📚 Loaded #{total_items} #{item_units} from Audible library",
          finished_items_summary(limit: limit),
          not_started_items_summary(limit: limit),
          started_items_summary(limit: limit),
        ].compact.join("\n")
      end

      private

      sig { void }
      def calculate_finished_unfinished_items
        return if @finished_items && @unfinished_items
        @finished_items, @unfinished_items = items.partition(&:finished?)
        @finished_items.sort! do |a, b|
          a_finish_time = a.finished_at
          b_finish_time = b.finished_at
          if a_finish_time && b_finish_time
            T.must(b_finish_time <=> a_finish_time)
          elsif a_finish_time
            -1
          elsif b_finish_time
            1
          else
            0
          end
        end
      end

      sig { void }
      def calculate_started_not_started_items
        return if @started_items && @not_started_items
        @started_items, @not_started_items = unfinished_items.partition(&:started?)
        @started_items.sort! { |a, b| b.percent_complete <=> a.percent_complete }
      end
    end
  end
end

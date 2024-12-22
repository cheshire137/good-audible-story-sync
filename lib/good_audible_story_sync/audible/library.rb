# frozen_string_literal: true
# typed: true
# encoding: utf-8

require "date"

module GoodAudibleStorySync
  module Audible
    class Library
      extend T::Sig

      sig { params(client: Client, options: Options).returns(Library) }
      def self.load_with_finish_times(client:, options:)
        load_finish_times = T.let(false, T::Boolean)
        library_file = options.library_file
        library_is_cached = File.exist?(library_file)
        library_cache_last_modified = library_is_cached ? File.mtime(library_file) : nil
        should_refresh_library = library_cache_last_modified &&
          library_cache_last_modified > options.refresh_cutoff_time

        if library_is_cached && should_refresh_library
          library = load_from_file(library_file)
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
          library.save_to_file(library_file)
        end

        library
      end

      sig { params(file_path: String).returns(Library) }
      def self.load_from_file(file_path)
        library = new
        library.load_from_file(file_path)
        library
      end

      sig { returns T::Array[LibraryItem] }
      attr_reader :items

      sig { params(items: T::Array[LibraryItem]).void }
      def initialize(items: [])
        @items = items
        @loaded_from_file = T.let(false, T::Boolean)
      end

      sig { returns Integer }
      def total_items
        items.size
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def save_to_file(file_path)
        puts "#{Util::SAVE_EMOJI} Saving Audible library data to file #{file_path}..."
        File.write(file_path, to_json)
        File.exist?(file_path) && !File.empty?(file_path)
      end

      sig { returns T::Boolean }
      def loaded_from_file?
        @loaded_from_file
      end

      sig { params(file_path: String).returns(T::Boolean) }
      def load_from_file(file_path)
        return false unless File.exist?(file_path)

        puts "#{Util::INFO_EMOJI} Loading Audible library from #{file_path}..."
        json_str = File.read(file_path)
        return false if json_str.strip.empty?

        data = T.let(JSON.parse(json_str), T::Array[Hash])
        @items = data.map { |item_data| LibraryItem.new(item_data) }

        @loaded_from_file = true
      end

      sig { returns T::Boolean }
      def any_finished_time_loaded?
        items.any? { |library_item| !library_item.finished_at.nil? }
      end

      sig { params(finish_times_by_asin: T::Hash[String, DateTime]).void }
      def populate_finish_times(finish_times_by_asin)
        items.each do |library_item|
          asin = library_item.asin
          if asin
            library_item.finished_at = finish_times_by_asin[asin]
          end
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
          not_started_items_summary(limit: 5),
          started_items_summary(limit: 5),
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

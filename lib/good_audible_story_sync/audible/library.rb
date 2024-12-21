# frozen_string_literal: true
# typed: true

require "date"

module GoodAudibleStorySync
  module Audible
    class Library
      extend T::Sig

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
      def unfinished_items
        calculate_finished_unfinished_items
        @unfinished_items
      end

      sig { returns Integer }
      def total_finished
        @total_finished ||= finished_items.size
      end

      sig { returns Integer }
      def total_unfinished
        @total_unfinished ||= unfinished_items.size
      end

      sig { returns String }
      def finished_item_units
        total_finished == 1 ? "book" : "books"
      end

      sig { returns String }
      def unfinished_item_units
        total_unfinished == 1 ? "book" : "books"
      end

      sig { returns String }
      def to_json
        JSON.pretty_generate(items.map(&:to_h))
      end

      private

      sig { void }
      def calculate_finished_unfinished_items
        return if @finished_items && @unfinished_items
        @finished_items, @unfinished_items = items.partition(&:finished?)
        @finished_items.sort! do |a, b|
          a_finish = T.must(a.finished_at)
          b_finish = T.must(b.finished_at)
          T.must(b_finish <=> a_finish)
        end
      end
    end
  end
end

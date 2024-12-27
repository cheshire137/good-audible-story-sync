# frozen_string_literal: true
# typed: true

module GoodAudibleStorySync
  module Storygraph
    class MarkFinishedFlow
      extend T::Sig

      sig do
        params(
          finish_dates_by_isbn: T::Hash[String, Date],
          storygraph_library: Library
        ).void
      end
      def self.run(finish_dates_by_isbn:, storygraph_library:)
        new(finish_dates_by_isbn: finish_dates_by_isbn, storygraph_library: storygraph_library).run
      end

      sig do
        params(
          finish_dates_by_isbn: T::Hash[String, Date],
          storygraph_library: Library
        ).void
      end
      def initialize(finish_dates_by_isbn:, storygraph_library:)
        @finish_dates_by_isbn = finish_dates_by_isbn
        @storygraph_library = storygraph_library
      end

      sig { void }
      def run
        @finish_dates_by_isbn.each do |isbn, finish_date|
          storygraph_book = @storygraph_library.find_by_isbn(isbn)
          if storygraph_book
            storygraph_finish_date = storygraph_book.finished_on
            if storygraph_finish_date.nil?
              puts "#{Util::INFO_EMOJI} Storygraph book with ISBN #{isbn} not marked as finished"
            elsif storygraph_finish_date == finish_date
              puts "#{Util::SUCCESS_EMOJI} Storygraph book with ISBN #{isbn} already " \
                "marked as finished on #{Util.pretty_date(finish_date)}"
            else
              puts "#{Util::WARNING_EMOJI} Storygraph book with ISBN #{isbn} marked finished on " \
                "#{Util.pretty_date(storygraph_finish_date)}, versus Audible finish date " \
                "#{Util.pretty_date(finish_date)}"
            end
          else
            puts "#{Util::WARNING_EMOJI} Book with ISBN #{isbn} not found in Storygraph library"
          end
        end
      end
    end
  end
end

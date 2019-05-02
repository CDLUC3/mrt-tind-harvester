require 'oai/client'

module Merritt
  module TIND
    class Feed
      include Enumerable

      def initialize(resp)
        @resp = resp
      end

      def each
        return enum_for(:each) unless block_given?

        @resp.each { |oai_record| yield Record.new(oai_record) }
      end

    end
  end
end

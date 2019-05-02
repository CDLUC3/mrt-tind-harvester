require 'oai/client'

module Merritt
  module TIND
    class Feed
      include Enumerable

      def initialize(resp)
        @resp = ensure_full_response(resp)
      end

      def each
        return enum_for(:each) unless block_given?

        @resp.each { |oai_record| yield Record.new(oai_record) }
      end

      private

      def ensure_full_response(resp)
        return resp unless resp.respond_to?(:resumption_token) # already wrapped
        return resp unless resp.resumption_token # nothing to paginate

        resp.full
      end

    end
  end
end

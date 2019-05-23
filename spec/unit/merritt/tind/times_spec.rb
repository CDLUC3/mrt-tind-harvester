require 'spec_helper'

module Merritt::TIND
  describe Times do
    describe :iso8601_range do
      it 'converts to iso8601' do
        from_time = Time.now.utc - 1
        until_time = Time.now.utc + 1
        from_iso8601, until_iso8601 = Times.iso8601_range(from_time, until_time)
        expect(from_iso8601).to eq(from_time.iso8601)
        expect(until_iso8601).to eq(until_time.iso8601)
      end

      it 'converts to UTC' do
        from_time = Time.now - 1
        until_time = Time.now + 1
        from_iso8601, until_iso8601 = Times.iso8601_range(from_time, until_time)
        expect(from_iso8601).to eq(from_time.utc.iso8601)
        expect(until_iso8601).to eq(until_time.utc.iso8601)
      end

      it 'accepts a nil from time' do
        until_time = Time.now + 1
        from_iso8601, until_iso8601 = Times.iso8601_range(nil, until_time)
        expect(from_iso8601).to be_nil
        expect(until_iso8601).to eq(until_time.utc.iso8601)
      end

      it 'accepts a nil until time' do
        from_time = Time.now - 1
        from_iso8601, until_iso8601 = Times.iso8601_range(from_time, nil)
        expect(from_iso8601).to eq(from_time.utc.iso8601)
        expect(until_iso8601).to be_nil
      end

      it 'accepts two nils' do
        from_iso8601, until_iso8601 = Times.iso8601_range(nil, nil)
        expect(from_iso8601).to be_nil
        expect(until_iso8601).to be_nil
      end

      it 'rejects invalid ranges' do
        from_time = Time.now.utc + 1
        until_time = Time.now.utc - 1
        expect {  Times.iso8601_range(from_time, until_time) }.to raise_error(RangeError)
      end

      it 'rejects non-times' do
        from_time = Date.today - 1
        until_time = Date.today + 1
        expect { Times.iso8601_range(from_time, until_time) }.to raise_error(ArgumentError)
      end
    end
  end
end

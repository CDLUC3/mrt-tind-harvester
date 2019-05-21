require 'spec_helper'

describe 'and_yield' do
  it 'yields' do
    e = instance_double(Array)
    expectation = expect(e).to receive(:each)
    (0..3).each do |i|
      expectation.and_yield(i)
    end

    a = []
    e.each do |i|
      a << i
    end
    expect(a).to eq([0, 1, 2, 3])
  end
end

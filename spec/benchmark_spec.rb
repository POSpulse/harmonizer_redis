require 'spec_helper'
require 'benchmark'

describe 'Benchmarking' do
  before :all do
    Redis.current = Redis.new(:driver => :hiredis)
  end

  before :each do
    Redis.current.flushall
    @to_add = []
    file = File.open('/Users/tianwang/Documents/POSpulse/shopscout_data/douglas/all.txt', 'r')
    file.each_line do |line|
      @to_add << line
    end
    file.close
  end

  it 'should add linkages quickly' do
    time = Benchmark.realtime do
      @to_add.each_with_index do |task_answer, index|
        new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer, category_id: 1)
        new_linkage.save
      end
    end
    expect(time).to be < 0
  end

  it 'should calculate similarities quickly' do
    @to_add.each_with_index do |task_answer, index|
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer, category_id: 1)
      new_linkage.save
    end

    time = Benchmark.realtime do
      HarmonizerRedis.calculate_similarities(1)
    end
    expect(time).to be < 0
  end
end



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

  it 'should add 200 linkages quickly', :benchmark do
    (0...@to_add.length-200).each do |index|
      new_linkage = HarmonizerRedis::Linkage.new(content: @to_add[index], category_id: 1)
      new_linkage.save
    end

    time = Benchmark.realtime do
      (@to_add.length-200...@to_add.length).each do |index|
        new_linkage = HarmonizerRedis::Linkage.new(content: @to_add[index], category_id: 2)
        new_linkage.save
      end
    end

    expect(time).to be < 0.5
  end

  it 'should calculate similarities quickly', :benchmark do
    @to_add.each_with_index do |task_answer, index|
      new_linkage = HarmonizerRedis::Linkage.new(content: task_answer, category_id: 1)
      new_linkage.save
    end

    time = Benchmark.realtime do
      HarmonizerRedis.calculate_similarities(1)
    end
    expect(time).to be < 3.0
  end

  it 'should add 200 similarities quickly', :benchmark do
    (0...@to_add.length-200).each do |index|
      new_linkage = HarmonizerRedis::Linkage.new(content: @to_add[index], category_id: 1)
      new_linkage.save
    end

    (@to_add.length-200...@to_add.length).each do |index|
      new_linkage = HarmonizerRedis::Linkage.new(content: @to_add[index], category_id: 2)
      new_linkage.save
    end

    time = Benchmark.realtime do
      HarmonizerRedis.calculate_similarities(2)
    end
    expect(time).to be < 0.3
  end

  it 'should calculate/retrieve similarities for 1 quickly', :benchmark do
    linkage_ids = []
    (@to_add.length-200...@to_add.length).each do |index|
      new_linkage = HarmonizerRedis::Linkage.new(content: @to_add[index], category_id: 1)
      new_linkage.save
      linkage_ids << new_linkage.id
    end

    time = Benchmark.realtime do
      linkage_ids.each do |linkage_id|
        my_linkage = HarmonizerRedis::Linkage.find(linkage_id)
        my_linkage.get_similarities(20)
      end
    end
    expect(time / linkage_ids.length.to_f).to be < 0.1
  end
end



require 'spec_helper'
require 'benchmark'

describe 'Benchmarking' do
  before :all do
    Redis.current = Redis.new
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
        new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer)
        new_linkage.save
      end
    end
    expect(time).to be < 10
  end

  it 'should calculate similarities quickly' do
    @to_add.each_with_index do |task_answer, index|
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer)
      new_linkage.save
    end

    time = Benchmark.realtime do
      HarmonizerRedis::Phrase.batch_calc_similarities
    end
    expect(time).to be < 10
  end

  it 'should add 200 similarities quickly' do
    (0...@to_add.length-200).each do |index|
      task_answer = @to_add[index]
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer)
      new_linkage.save
    end

    HarmonizerRedis::Phrase.batch_calc_similarities

    time = Benchmark.realtime do
      (@to_add.length-200...@to_add.length).each do |index|
        task_answer = @to_add[index]
        new_linkage = HarmonizerRedis::Linkage.new(id: index, content: task_answer)
        new_linkage.save
      end

      HarmonizerRedis::Phrase::batch_calc_similarities

    end

    expect(time).to be < 0

  end

  # it 'should add 1 entry quickly' do
  #   (0...@to_add.length).each do |i|
  #     new_linkage = HarmonizerRedis::Linkage.new(id: i, content: @to_add[i])
  #     new_linkage.save
  #   end
  #
  #   time = Benchmark.realtime do
  #     new_linkage = HarmonizerRedis::Linkage.new(id: @to_add.length, content: 'this has not existed')
  #     new_linkage.save
  #   end
  #
  #   expect(time).to be < 0
  # end

end
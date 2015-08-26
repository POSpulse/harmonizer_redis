require 'spec_helper'

describe 'Integration Tests' do
  before :all do
    Redis.current = Redis.new(driver: :hiredis)
  end

  before :each do
    Redis.current.flushall
    data = [['Abcd.zzz', 1], ['abcdzzz', 1], ['abcdefg', 1],
            ['hijk lmnop', 1], ['abcd zzz', 2], ['zzzefg', 2]]
    data.each_with_index do |entry, index|
      text, category_id = entry
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: text, category_id: category_id)
      new_linkage.save
    end

  end



  it "should load a linkage" do
    my_linkage = HarmonizerRedis::Linkage.find(0)
    expect(my_linkage.content).to eq('Abcd.zzz')
    expect(my_linkage.corrected).to eq('Abcd.zzz')
  end

  it "should allow separate calculations" do
    # Batch calculate similarities
    HarmonizerRedis.calculate_similarities(2)
  end

  it "should retrieve similarities for a linkage" do
    HarmonizerRedis.calculate_similarities(1)
    my_linkage = HarmonizerRedis::Linkage.find(0)
  end

  it "should combine linkage's phrase with another phrase" do
    my_linkage = HarmonizerRedis::Linkage.find(0)
    my_linkage.merge_with_phrase(selection_id)
  end

  it "should get probable labels for a linkage" do
  end

  it "should get similar phrases for combination" do

  end
end
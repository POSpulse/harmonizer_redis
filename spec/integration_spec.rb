require 'spec_helper'

describe 'Integration Tests' do
  before :all do
    Redis.current = Redis.new(driver: :hiredis)
  end

  before :each do
    Redis.current.flushall
    data = [['Abcd.zzz', 1], ['abcd zzz', 1], ['abcdefg', 1],
            ['hijk lmnop', 1], ['abcdzzz', 2], ['zzzefg', 2]]
    data.each_with_index do |entry, index|
      text, category_id = entry
      puts "#{text}, #{category_id}, #{index}"
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: text, category_id: category_id)
      new_linkage.save
    end

  end

  it "should allow separate calculations" do
    # Batch calculate similarities
    HarmonizerRedis.calculate_similarities(2)

  end

  it "should load a linkage" do
    my_linkage.content
    my_linkage.correction
  end

  it "should combine linkage's phrase with another phrase" do
    my_linkage.merge_with_phrase(selection_id)
  end

  it "should get probable labels for a linkage" do

  end

  it "should get similar phrases for combination" do

  end
end
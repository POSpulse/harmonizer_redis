require 'spec_helper'

describe HarmonizerRedis::IdfScorer do
  before :all do
    Redis.current = Redis.new
  end

  before :each do
    Redis.current.flushall
    phrases = ['this this is test', 'test is this', 'this is testing']
    phrases.each_with_index do |phrase, index|
      new_linkage = HarmonizerRedis::Linkage.new(id:index, content:phrase, category_id: 1)
      new_linkage.save
    end
  end

  it 'should add documents' do
    expect(HarmonizerRedis::IdfScorer.get_count('this')).to eq(4)
    expect(HarmonizerRedis::IdfScorer.get_doc_freq('this')).to eq(3)
  end

  it 'should calculate the tfidf for a word' do
    expect(HarmonizerRedis::IdfScorer.get_score('testing')).to be_within(0.01).of(1.071)
  end

end

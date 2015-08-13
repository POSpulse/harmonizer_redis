require 'spec_helper'

describe HarmonizerRedis::TfidfTable do
  before :all do
    Redis.current = Redis.new
  end

  before :each do
    Redis.current.flushall
    phrases = ['this this is test', 'test is this', 'this is testing']
    phrases.each_with_index do |phrase, index|
      new_linkage = HarmonizerRedis::Linkage.new(id:index, content:phrase)
      new_linkage.save
    end
  end

  it 'should add documents' do
    expect(HarmonizerRedis::TfidfTable.get_count('this')).to eq(4)
    expect(HarmonizerRedis::TfidfTable.get_doc_freq('this')).to eq(3)
  end

  it 'should handle merging phrase groups' do
    HarmonizerRedis::PhraseGroup.merge(0, 1)
    expect(HarmonizerRedis::TfidfTable.get_count('this')).to eq(4)
    expect(HarmonizerRedis::TfidfTable.get_doc_freq('this')).to eq(2)
    expect(HarmonizerRedis::TfidfTable.get_doc_freq('test')).to eq(1)

  end

  it 'should calculate the tfidf for a word' do

  end
end
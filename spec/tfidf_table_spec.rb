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
    expect(HarmonizerRedis::TfidfTable.get_score('test')).to eq(0.0)
    expect(HarmonizerRedis::TfidfTable.get_score('testing')).to be_within(0.01).of(0.405)
  end

  it 'should calculate score for a phrase' do
    matrix = HarmonizerRedis::TfidfTable.calc_matrix('this is a test')
    expect(matrix.length).to eq(4)
    matrix.each do |word, score|
      score != 0.0
    end
  end

  it 'should calculate phrase similarity' do
    matrix_a = HarmonizerRedis::TfidfTable.calc_matrix('this is testing')
    matrix_b = HarmonizerRedis::TfidfTable.calc_matrix('test is this')
    cos_similarity = HarmonizerRedis::TfidfTable.cos_similarity(matrix_a, matrix_b)
    expect(cos_similarity).to be > 0.0
    expect(cos_similarity).to be < 1.0
  end
end
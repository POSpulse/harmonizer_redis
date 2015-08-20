require 'spec_helper'

describe HarmonizerRedis::IdfScorer do
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
    expect(HarmonizerRedis::IdfScorer.get_count('this')).to eq(4)
    expect(HarmonizerRedis::IdfScorer.get_doc_freq('this')).to eq(3)
  end

  it 'should handle merging phrase groups' do
    HarmonizerRedis::PhraseGroup.merge(0, 1)
    expect(HarmonizerRedis::IdfScorer.get_count('this')).to eq(4)
    expect(HarmonizerRedis::IdfScorer.get_doc_freq('this')).to eq(2)
    expect(HarmonizerRedis::IdfScorer.get_doc_freq('test')).to eq(1)

  end

  it 'should calculate the tfidf for a word' do
    expect(HarmonizerRedis::IdfScorer.get_score('testing')).to be_within(0.01).of(1.071)
  end

  it 'should calculate score for a phrase' do
    matrix = HarmonizerRedis::IdfScorer.calc_soft_matrix('this is a test')
    expect(matrix.length).to eq(4)
    matrix.each do |word, score|
      score != 0.0
    end
  end

  it 'should calculate phrase similarity' do
    matrix_a = HarmonizerRedis::IdfScorer.calc_soft_matrix('this is testing')
    matrix_b = HarmonizerRedis::IdfScorer.calc_soft_matrix('test is this')
    matrix_a_dump = HarmonizerRedis::IdfScorer.serialize_matrix(matrix_a)
    matrix_b_dump = HarmonizerRedis::IdfScorer.serialize_matrix(matrix_b)
    cos_similarity = WhiteSimilarity.soft_cos_similarity(matrix_a_dump, matrix_b_dump)
    expect(cos_similarity).to be > 0.0
    expect(cos_similarity).to be < 1.0
  end
end
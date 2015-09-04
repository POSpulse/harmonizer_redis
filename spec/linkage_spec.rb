require 'spec_helper'

describe HarmonizerRedis::Linkage do
  before :all do
    Redis.current = Redis.new
  end

  before :each do
    Redis.current.flushall
    @linkage = HarmonizerRedis::Linkage.new(content: 'testing', category_id: 3)
  end

  it '#new' do
    expect(@linkage).to be_instance_of(HarmonizerRedis::Linkage)
    expect(@linkage.content).to eq('testing')
    expect(@linkage.category_id).to eq(3)
  end

  it '#save' do
    @linkage.save
    expect(Redis.current.sismember("#{@linkage.class}:set", @linkage.id)).to be true
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:content")).to eq('testing')
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:category_id")).to eq('3')
    expect(Redis.current.smembers("HarmonizerRedis::Category:3:linkage_set").length).to eq(1)
  end

  it 'should set old phrase if matches content' do
    @old_phrase = HarmonizerRedis::Linkage.new(id: 1, content: '  tEsTiNg ', category_id: 2)
    @old_phrase.save
    @linkage.save
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('0')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('testing')
  end

  it 'should create new phrase if content is new' do
    @old_phrase = HarmonizerRedis::Linkage.new(id: 1, content: 'different', category_id: 2)
    @old_phrase.save
    @linkage.save
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('1')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('different')
    expect(Redis.current.get('HarmonizerRedis::Phrase:1:content')).to eq('testing')
  end



end
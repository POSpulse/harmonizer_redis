require 'spec_helper'

describe HarmonizerRedis::Linkage do
  before :all do
    Redis.current = Redis.new
  end

  before :each do
    Redis.current.flushall
    @linkage = HarmonizerRedis::Linkage.new(id: 5, content: 'testing')
  end

  it '#new' do
    @linkage.should be_an_instance_of HarmonizerRedis::Linkage
    @linkage.id.should == 5
    @linkage.content.should == 'testing'
  end

  it '#save' do
    @linkage.save
    expect(Redis.current.sismember("#{@linkage.class}:set", @linkage.id)).to be true
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:content")).to eq('testing')
  end

  it 'should set old phrase if matches content' do
    @old_phrase = HarmonizerRedis::Linkage.new(id: 1, content: '  tEsTiNg ')
    @old_phrase.save
    @linkage.save
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('HarmonizerRedis::Phrase:0')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('testing')
  end

  it 'should create new phrase if content is new' do
    @old_phrase = HarmonizerRedis::Linkage.new(id: 1, content: 'different')
    @old_phrase.save
    @linkage.save
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('HarmonizerRedis::Phrase:1')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('different')
    expect(Redis.current.get('HarmonizerRedis::Phrase:1:content')).to eq('testing')
  end

end
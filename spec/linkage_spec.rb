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
    expect(@linkage).to be_instance_of(HarmonizerRedis::Linkage)
    expect(@linkage.id).to eq(5)
    expect(@linkage.content).to eq('testing')
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
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('0')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('testing')
  end

  it 'should create new phrase if content is new' do
    @old_phrase = HarmonizerRedis::Linkage.new(id: 1, content: 'different')
    @old_phrase.save
    @linkage.save
    expect(Redis.current.get("#{@linkage.class}:#{@linkage.id}:phrase")).to eq('1')
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:content')).to eq('different')
    expect(Redis.current.get('HarmonizerRedis::Phrase:1:content')).to eq('testing')
  end

  it '#merge_with_phrase' do
    @linkage.save
    new_linkage = HarmonizerRedis::Linkage.new(id: 6, content: 'testin')
    new_linkage.save
    new_phrase_id = HarmonizerRedis::Linkage.get_phrase_id(new_linkage.id)
    HarmonizerRedis::Linkage.merge_with_phrase(@linkage.id, new_phrase_id)
    expect(HarmonizerRedis::Linkage.get_phrase_group_id(@linkage.id)).to_not eq(0)
    expect(HarmonizerRedis::Linkage.get_phrase_group_id(@linkage.id)).to eq(HarmonizerRedis::Linkage.get_phrase_group_id(new_linkage.id))
  end

  it '#get_true_label and #set_true_label' do
    @linkage.save
    expect(HarmonizerRedis::Linkage.get_true_label(@linkage.id)).to eq('testing')

    new_linkage = HarmonizerRedis::Linkage.new(id: 6, content: 'testin')
    new_linkage.save
    new_phrase_id = HarmonizerRedis::Linkage.get_phrase_id(new_linkage.id)

    expect(HarmonizerRedis::Linkage.get_true_label(new_linkage.id)).to eq('testin')

    HarmonizerRedis::Linkage.merge_with_phrase(@linkage.id, new_phrase_id)

    expect(HarmonizerRedis::Linkage.get_true_label(new_linkage.id)).to eq(HarmonizerRedis::Linkage.get_true_label(@linkage.id))

    HarmonizerRedis::Linkage.set_true_label(new_linkage.id, 'testinggg')

    expect(HarmonizerRedis::Linkage.get_true_label(new_linkage.id)).to eq('testinggg')
    expect(HarmonizerRedis::Linkage.get_true_label(@linkage.id)).to eq('testinggg')

  end


end
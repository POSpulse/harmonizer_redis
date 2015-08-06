require 'spec_helper'

describe HarmonizerRedis::Linkage do
  before :all do
    Redis.current.flushall
  end

  before :each do
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

end
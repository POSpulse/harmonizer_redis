require 'spec_helper'

describe HarmonizerRedis::PhraseGroup do
  before :all do
    Redis.current = Redis.new
  end

  before :each do
    Redis.current.flushall
  end

  it 'adding a phrase should trigger adding a phrase_group' do
    new_phrase = HarmonizerRedis::Phrase.new('testing')
    new_phrase.save

    expect(Redis.current.get('HarmonizerRedis::PhraseGroup:0:label')).to eq('testing')
    expect(Redis.current.smembers('HarmonizerRedis::PhraseGroup:0:phrase_set')).to eq(['0'])
    expect(Redis.current.get('HarmonizerRedis::Phrase:0:phrase_group')).to eq('0')
  end

  it 'should merge' do
    phrase_one = HarmonizerRedis::Phrase.new('testing')
    phrase_two = HarmonizerRedis::Phrase.new('testing1')
    phrase_three = HarmonizerRedis::Phrase.new('hello')
    phrase_four = HarmonizerRedis::Phrase.new('hello1')
    phrase_one.save
    phrase_two.save
    phrase_three.save
    phrase_four.save

    HarmonizerRedis::PhraseGroup.merge(HarmonizerRedis::Phrase.get_phrase_group(phrase_one.id),
                                       HarmonizerRedis::Phrase.get_phrase_group(phrase_two.id))

    HarmonizerRedis::PhraseGroup.merge(HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id),
                                       HarmonizerRedis::Phrase.get_phrase_group(phrase_four.id))
    phrase_one_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_one.id)
    phrase_two_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_two.id)
    phrase_three_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id)
    phrase_four_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id)
    expect(phrase_one_group_id).to eq(phrase_two_group_id)
    expect(phrase_three_group_id).to eq(phrase_four_group_id)
    expect(phrase_two_group_id).to_not eq(phrase_three_group_id)

    HarmonizerRedis::PhraseGroup.merge(HarmonizerRedis::Phrase.get_phrase_group(phrase_one.id),
                                       HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id))

    phrase_one_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_one.id)
    phrase_two_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_two.id)
    phrase_three_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id)
    phrase_four_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_three.id)

    expect(phrase_one_group_id).to eq(phrase_two_group_id)
    expect(phrase_two_group_id).to eq(phrase_three_group_id)
    expect(phrase_three_group_id).to eq(phrase_four_group_id)

  end
end




require 'spec_helper'

describe 'Integration Tests' do
  before :all do
    Redis.current = Redis.new(driver: :hiredis)
  end

  before :each do
    Redis.current.flushall
    data = [['Abcd.zzz', 1], ['abcDzzz', 1], ['abcdefg', 1],
            ['hijk lmnop', 1], ['abcd zzz', 2], ['zzzefg', 2]]
    @id_map = {}
    data.each_with_index do |entry, index|
      text, category_id = entry
      new_linkage = HarmonizerRedis::Linkage.new(id: index, content: text, category_id: category_id)
      new_linkage.save
      @id_map[index] = new_linkage.id
    end

  end

  it "should load a linkage" do
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    expect(my_linkage.content).to eq('Abcd.zzz')
    expect(my_linkage.corrected).to eq('Abcd.zzz')
  end

  it "should return whether more linkages have been added to same category" do
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    expect(my_linkage.is_category_changed?).to be_truthy
  end

  it "should allow separate calculations" do
    # Batch calculate similarities
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    HarmonizerRedis.calculate_similarities(2)
    expect(my_linkage.get_similarities(20)).to eq([])
  end

  it "should retrieve similarities for a linkage" do
    HarmonizerRedis.calculate_similarities(1)
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    similar_phrases = my_linkage.get_similarities(20)
    expect(similar_phrases.length).to eq(2)
    expect(similar_phrases[0][-1]).to eq("1")
    expect(similar_phrases[1][-1]).to eq("2")
  end

  it "should combine linkage's phrase with another phrase" do
    HarmonizerRedis.calculate_similarities(1)
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    other_linkage = HarmonizerRedis::Linkage.find(@id_map[1])
    my_linkage.merge_with_phrase(1)
    my_linkage_group = Redis.current.get("HarmonizerRedis::Category:#{my_linkage.category_id}:#{my_linkage.phrase_id}:group")
    other_linkage_group = Redis.current.get("HarmonizerRedis::Category:#{other_linkage.category_id}:#{other_linkage.phrase_id}:group")
    expect(my_linkage_group).to eq(other_linkage_group)
  end

  it "should prevent linkage combos for phrases that are in different categories" do
    HarmonizerRedis.calculate_similarities(1)
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    other_linkage = HarmonizerRedis::Linkage.find(@id_map[5])
    expect{my_linkage.merge_with_phrase(other_linkage.phrase_id)}.to raise_error("Invalid Phrase ID(s) given!")
  end

  it "should do nothing if linkage tries to combine with it's own phrase/another phrase in group" do
    HarmonizerRedis.calculate_similarities(1)
    my_linkage = HarmonizerRedis::Linkage.find(@id_map[0])
    other_linkage = HarmonizerRedis::Linkage.find(@id_map[1])
    my_linkage.merge_with_phrase(other_linkage.phrase_id)
    my_linkage.merge_with_phrase(other_linkage.phrase_id)
    my_linkage_group = Redis.current.get("HarmonizerRedis::Category:#{my_linkage.category_id}:#{my_linkage.phrase_id}:group")
    other_linkage_group = Redis.current.get("HarmonizerRedis::Category:#{other_linkage.category_id}:#{other_linkage.phrase_id}:group")
    expect(Redis.current.smembers(my_linkage_group)).to eq(Redis.current.smembers(other_linkage_group))
  end

  it "similarities do not show phrases in the same group" do
    HarmonizerRedis.calculate_similarities(1)
    linkage_a = HarmonizerRedis::Linkage.find(@id_map[0])
    linkage_b = HarmonizerRedis::Linkage.find(@id_map[1])
    linkage_a.merge_with_phrase(linkage_b.phrase_id)
    simplified_a = linkage_a.get_similarities(20).map { |x| x[-1] }
    simplified_b = linkage_b.get_similarities(20).map { |x| x[-1] }
    expect(simplified_a.to_set.include?(linkage_b.phrase_id)).to be_falsey
    expect(simplified_b.to_set.include?(linkage_a.phrase_id)).to be_falsey
  end

  it "should let the label that is already set persist" do
    linkage_a = HarmonizerRedis::Linkage.find(@id_map[0])
    linkage_b = HarmonizerRedis::Linkage.find(@id_map[1])
    linkage_c = HarmonizerRedis::Linkage.find(@id_map[2])
    linkage_b.set_corrected_label('ABCD')
    linkage_a.merge_with_phrase(linkage_b.phrase_id)
    expect(linkage_a.corrected).to eq('ABCD')
    linkage_c.merge_with_phrase(linkage_a.phrase_id)
    expect(linkage_c.corrected).to eq('ABCD')
    expect(linkage_b.corrected).to eq('ABCD')

  end


  it "should get probable labels for a linkage" do
    HarmonizerRedis.calculate_similarities(1)
    HarmonizerRedis.calculate_similarities(2)
    linkage_a = HarmonizerRedis::Linkage.find(@id_map[0])
    linkage_b = HarmonizerRedis::Linkage.find(@id_map[1])
    linkage_c = HarmonizerRedis::Linkage.find(@id_map[4])
    linkage_a.merge_with_phrase(linkage_b.phrase_id)
    linkage_c.set_corrected_label('ABCD')
    suggested = linkage_a.recommend_labels
    expect(suggested[0][0]).to eq('ABCD')
  end

end
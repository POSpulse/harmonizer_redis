require 'harmonizer_redis'

Redis.current = Redis.new(:driver => :hiredis)

Redis.current.flushall
douglas_path = '/Users/tianwang/Documents/POSpulse/shopscout_data/douglas/all.txt'
ey_path = '/Users/tianwang/Documents/POSpulse/shopscout_data/ey/raw_store_name_input.txt'
to_add = []
file = File.open(ey_path, 'r')
file.each_line do |line|
  to_add << line
end
file.close

to_add.each_with_index do |text, index|
  new_linkage = HarmonizerRedis::Linkage.new(id: index, content: text)
  new_linkage.save
end

time = Benchmark.realtime do
  HarmonizerRedis::Phrase.batch_calc_similarities
end

puts "Time: #{time}"


def get_similar_ones(phrase)
  phrase_id = HarmonizerRedis::Phrase.find_by_content(phrase)
  return false if phrase_id.nil?
  id_list = Redis.current.zrevrange("HarmonizerRedis::Phrase:#{phrase_id}:similarities", 0, 20, :with_scores => true)
  id_list.each do |phrase_id, score|
    puts "#{HarmonizerRedis::Phrase.get_content(phrase_id)}\t#{score}"
  end
end

puts 'Done. Now enter tests. q to quit'
input = gets.chomp
while input != 'q' do
  get_similar_ones(input)
  puts 'ask again'
  input = gets.chomp
end
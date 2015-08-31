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

file = File.open(douglas_path, 'r')
file.each_line do |line|
  to_add << line
end

to_add.each_with_index do |text, index|
  new_linkage = HarmonizerRedis::Linkage.new(id: index, content: text, category_id: 1)
  new_linkage.save
end

time = Benchmark.realtime do
  HarmonizerRedis.calculate_similarities(1)
end


### Functions
def print_list(list)
  list.each do |entry|
    entry.each do |item|
      print "#{item}\t"
    end
    print "\n"
  end
end
puts "Time: #{time}"

puts 'Done. Now enter tests.'

linkage_list = Redis.current.smembers("HarmonizerRedis::Linkage:set")
input = 'ha'
current_index = 0
while input[0] != 'quit'
  curr = HarmonizerRedis::Linkage.find(linkage_list[current_index])
  puts "#{curr.content}"
  input = gets.chomp.downcase.split(',')
  if input[0] == 'similar'
    print_list(curr.get_similarities(10))
  elsif input[0] == 'merge'
    phrase_id = input[1].to_i
    curr.merge_with_phrase(phrase_id)
    puts 'Merged!'
  elsif input[0] == 'recommend'
    print_list(curr.recommend_labels)
  elsif input[0] == 'set'
    unless input.length >= 2
      raise 'Input too short'
    end
    curr.set_corrected_label(input[1])
  else
    current_index += 1
  end
end

linkage_list.each do |linkage_id|
  linkage = HarmonizerRedis.Linkage.find(linkage_id)
  puts "#{linkage.content}\t#{linkage.corrected}"
end

require 'harmonizer_redis/version'
require 'harmonizer_redis/base_object'
require 'harmonizer_redis/linkage'
require 'harmonizer_redis/phrase'
require 'harmonizer_redis/phrase_group'
require 'harmonizer_redis/idf_scorer'
require 'harmonizer_redis/white_similarity'
require 'harmonizer_redis/category'
require 'active_support/all'
require 'redis/connection/hiredis'
require 'redis'

include WhiteSimilarity

module HarmonizerRedis
  ### Calculate Similarities. Store them with the category
  def HarmonizerRedis.calculate_similarities(category_id)
    if !Category.is_valid?(category_id)
      raise "Category ID: #{category_id} is invalid"
    end
    linkages = Category.get_linkage_list(category_id)
    phrase_set = Set.new
    linkages.each do |linkage_id|
      phrase_set.add(Linkage.get_phrase_id(linkage_id))
    end
    phrase_id_list = phrase_set.to_a

    phrase_id_list.each do |id|
      content = self.get_content(id)
      Redis.current.set("#{self}:#{id}:matrix",
                        IdfScorer.serialize_matrix(IdfScorer.calc_soft_matrix(content)))
    end

    matrix_list = phrase_id_list.map { |x| self.get_matrix(x) }

    Redis.current.pipelined do
      (0...phrase_id_list.length).each do |i|
        (i + 1...phrase_id_list.length).each do |j|
          id_x = phrase_id_list[i]
          id_y = phrase_id_list[j]
          score = self.calc_soft_pair_similarity(matrix_list[i], matrix_list[j])
          unless score < 0.2
            Redis.current.zadd("HarmonizerRedis::Category:#{category_id}:#{id_x}:sims", score, id_y)
            Redis.current.zadd("HarmonizerRedis::Category:#{category_id}:#{id_y}:sims", score, id_x)
          end
        end
      end
    end
  end


  ### String PreProcessing
  def HarmonizerRedis.normalize_string(string)
    ActiveSupport::Inflector.transliterate(string.strip.downcase).
        split(/[^\p{L}0-9]/).delete_if { |x| x.length == 0 }.join(' ')
  end

end

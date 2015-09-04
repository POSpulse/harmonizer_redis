require 'harmonizer_redis/version'
require 'harmonizer_redis/base_object'
require 'harmonizer_redis/linkage'
require 'harmonizer_redis/phrase'
require 'harmonizer_redis/idf_scorer'
require 'harmonizer_redis/white_similarity'
require 'harmonizer_redis/category'
require 'active_support/all'
require 'redis/connection/hiredis'
require 'redis'

include WhiteSimilarity

module HarmonizerRedis
  ### Calculate Similarities. Store them with the category
  class << self
    def calculate_similarities(category_id)
      unless Category.valid?(category_id)
        raise "Category ID: #{category_id} is invalid"
      end

      phrase_id_list = Category.get_phrase_list(category_id)

      matrix_list = Category.get_matrices(category_id, phrase_id_list)

      Redis.current.pipelined do
        (0...phrase_id_list.length).each do |i|
          (i + 1...phrase_id_list.length).each do |j|
            id_x = phrase_id_list[i]
            id_y = phrase_id_list[j]
            score = Phrase.calc_soft_pair_similarity(matrix_list[i], matrix_list[j])
            unless score < 0.2
              add_similarity_entry(id_x, id_y, score, category_id)
            end
          end
        end
      end

      Category.reset_changed(category_id)
    end


    ### String PreProcessing
    def normalize_string(string)
      ActiveSupport::Inflector.transliterate(string.strip.downcase).
          split(/[^\p{L}0-9]/).delete_if { |x| x.length == 0 }.join(' ')
    end

    ### Helper

    def add_similarity_entry(id_x, id_y, score, category_id)
      Redis.current.zadd("HarmonizerRedis::Category:#{category_id}:#{id_x}:sims", score, id_y)
      Redis.current.zadd("HarmonizerRedis::Category:#{category_id}:#{id_y}:sims", score, id_x)
    end

    private :add_similarity_entry
  end

end

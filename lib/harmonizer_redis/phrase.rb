module HarmonizerRedis
  class Phrase < BaseObject
    attr_accessor :content

    def initialize(content)
      @content = content
    end

    def save
      super()
      Redis.current.set("#{self.class}:[#{@content}]", "#{@id}")
      Redis.current.sadd('HarmonizerRedis::Phrase:content_set', @content)
    end

    def self.find_by_content(content)
      Redis.current.get("#{self}:[#{content}]")
    end

    def calculate_similarities
      phrase_list = Redis.current.smembers('HarmonizerRedis::Phrase:content_set')
      id_list = []
      phrase_list.each do |phrase|
        id_list << self.class.find_by_content(phrase)
      end
      Redis.current.pipelined do
        phrase_list.each_with_index do |phrase, index|
          score = FuzzyCompare.white_similarity(@content, phrase)
          other_id = id_list[index]
          Redis.current.zadd("HarmonizerRedis::Phrase:#{id}:similarity_hash", other_id, score)
          Redis.current.zadd("HarmonizerRedis::Phrase:#{other_id}:similarity_hash", @id, score)
        end
      end
    end

    def self.batch_calc_similarities
      phrase_list = Redis.current.smembers('HarmonizerRedis::Phrase:content_set')
      id_list = phrase_list.map { |x| self.find_by_content(x)}
      Redis.current.pipelined do
        phrase_list.each_with_index do |phrase, i|
          (i + 1...phrase_list.length).each do |j|
            other_phrase = phrase_list[j]
            other_id = id_list[j]
            id = id_list[i]
            score = FuzzyCompare.white_similarity(phrase, other_phrase)
            Redis.current.zadd("HarmonizerRedis::Phrase#{id}:similarities", other_id, score)
            Redis.current.zadd("HarmonizerRedis::Phrase#{other_id}:similarities", id, score)
          end
        end
      end
    end

  end
end
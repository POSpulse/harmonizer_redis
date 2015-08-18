module HarmonizerRedis
  class Phrase < BaseObject
    attr_accessor :content, :phrase_group

    def initialize(content)
      @content = content
    end

    def save
      super()
      Redis.current.set("#{self.class}:#{@id}:matrix", Marshal.dump(IdfScorer.calc_matrix(@content)))
      Redis.current.set("#{self.class}:[#{@content}]", "#{@id}")
      Redis.current.sadd("#{self.class}:new_set", "#{@id}")
      new_phrase_group = HarmonizerRedis::PhraseGroup.new(@id)
      new_phrase_group.save
    end

    class << self
      def find_by_content(content)
        Redis.current.get("#{self}:[#{content}]")
      end

      def get_content(phrase_id)
        Redis.current.get("#{self}:#{phrase_id}:content")
      end

      #returns get phrase_group_id for phrase_id
      def get_phrase_group(phrase_id)
        Redis.current.get("#{self}:#{phrase_id}:phrase_group")
      end

      #returns sets phrase_group for phrase_id
      def set_phrase_group(phrase_id, phrase_group_id)
        Redis.current.set("#{self}:#{phrase_id}:phrase_group", phrase_group_id)
      end

      #get matrix (in the form of a hash 'word' => value) for phrase with phrase_id
      def get_matrix(phrase_id)
        byte_stream = Redis.current.get("#{self}:#{phrase_id}:matrix")
        if byte_stream
          Marshal.load(byte_stream)
        else
          nil
        end
      end

      def merge_phrases(phrase_one_id, phrase_two_id, label = nil)
        phrase_one_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_one_id)
        phrase_two_group_id = HarmonizerRedis::Phrase.get_phrase_group(phrase_two_id)
        HarmonizerRedis::PhraseGroup.merge(phrase_one_group_id, phrase_two_group_id, label)
      end

      def calc_pair_similarity(phrase_a, phrase_b, phrase_a_matrix, phrase_b_matrix)
        idf_similarity = IdfScorer.cos_similarity(phrase_a_matrix, phrase_b_matrix)
        white_similarity = FuzzyCompare.white_similarity(phrase_a, phrase_b)
        (idf_similarity + white_similarity) * -0.5
      end

      def batch_calc_similarities
        new_id_list = Redis.current.smembers("#{self}:new_set")
        old_id_list = Redis.current.smembers("#{self}:old_set")
        new_phrase_list = new_id_list.map { |x| self.get_content(x) }
        old_phrase_list = old_id_list.map { |x| self.get_content(x) }
        new_matrix_list = new_id_list.map { |x| self.get_matrix(x) }
        old_matrix_list = old_id_list.map { |x| self.get_matrix(x) }

        Redis.current.pipelined do
          (0...new_id_list.length).each do |i|
            (0...old_id_list.length).each do |j|
              id_x = new_id_list[i]
              id_y = old_id_list[j]
              score = self.calc_pair_similarity(new_phrase_list[i], old_phrase_list[j],
                                                new_matrix_list[i], old_matrix_list[j])
              unless score > -0.2
                Redis.current.zadd("HarmonizerRedis::Phrase:#{id_x}:similarities", score, id_y)
                Redis.current.zadd("HarmonizerRedis::Phrase:#{id_y}:similarities", score, id_x)
              end
            end
          end

          (0...new_id_list.length).each do |i|
            (i + 1...new_id_list.length).each do |j|
              id_x = new_id_list[i]
              id_y = new_id_list[j]
              score = self.calc_pair_similarity(new_phrase_list[i], new_phrase_list[j],
                                                new_matrix_list[i], new_matrix_list[j])
              unless score > -0.2
                Redis.current.zadd("HarmonizerRedis::Phrase:#{id_x}:similarities", score, id_y)
                Redis.current.zadd("HarmonizerRedis::Phrase:#{id_y}:similarities", score, id_x)
              end
            end
          end
        end

        Redis.current.sunionstore("#{self}:old_set", "#{self}:old_set", "#{self}:new_set")
        Redis.current.del("#{self}:new_set")
      end
    end
  end
end
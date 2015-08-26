module HarmonizerRedis
  class Phrase < BaseObject
    attr_accessor :content, :phrase_group

    def initialize(content)
      @content = content
    end

    def save
      super()
      new_phrase_group = HarmonizerRedis::PhraseGroup.new(@id)
      new_phrase_group.save
      Redis.current.set("#{self.class}:[#{@content}]", "#{@id}")

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
        serialized = Redis.current.get("#{self}:#{phrase_id}:matrix")
        if serialized
          serialized
        else
          nil
        end
      end

      def in_same_group?(phrase_a_id, phrase_b_id)
        self.get_phrase_group(phrase_a_id) == self.get_phrase_group(phrase_b_id)
      end

      def merge_phrases(phrase_one_id, phrase_two_id, label = nil)
        phrase_one_group_id = self.get_phrase_group(phrase_one_id)
        phrase_two_group_id = self.get_phrase_group(phrase_two_id)
        PhraseGroup.merge(phrase_one_group_id, phrase_two_group_id, label)
      end

      def calc_pair_similarity(phrase_a, phrase_b, phrase_a_matrix, phrase_b_matrix)
        idf_similarity = IdfScorer.cos_similarity(phrase_a_matrix, phrase_b_matrix)
        white_similarity = WhiteSimilarity.score(phrase_a, phrase_b)
        (idf_similarity + white_similarity) * -0.5
      end

      def calc_soft_pair_similarity(phrase_a_matrix, phrase_b_matrix)
        WhiteSimilarity.soft_cos_similarity(phrase_a_matrix, phrase_b_matrix)
      end

    end
  end
end
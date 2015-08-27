module HarmonizerRedis
  class Phrase < BaseObject
    attr_accessor :content

    def initialize(content)
      @content = content
    end

    def save
      super()
      HarmonizerRedis::IdfScorer.add_document(@id)
      Redis.current.set("#{self.class}:[#{@content}]", "#{@id}")
    end

    class << self
      def find_by_content(content)
        Redis.current.get("#{self}:[#{content}]")
      end

      def get_content(phrase_id)
        Redis.current.get("#{self}:#{phrase_id}:content")
      end

      #get a serialized version of the matrix.
      def get_matrix(phrase_id)
        serialized = Redis.current.get("#{self}:#{phrase_id}:matrix")
        if serialized
          serialized
        else
          nil
        end
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
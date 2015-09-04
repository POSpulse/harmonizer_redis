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

      # Setup
      def add_linkage(phrase_id, linkage_id, category_id)
        add_linkage_id(phrase_id, linkage_id)
        add_category_id(phrase_id, category_id)
      end

      # Linkages
      def add_linkage_id(phrase_id, linkage_id)
        Redis.current.zincrby(linkage_set_key(phrase_id), 1, Linkage.get_content(linkage_id))
      end

      def get_linkage_count(phrase_id)
        Redis.current.zcard(linkage_set_key(phrase_id))
      end

      def get_popular_linkages(phrase_id, number = 5)
        if number <= 0
          raise "number must be >= 0"
        end
        Redis.current.zrevrange(linkage_set_key(phrase_id), 0, number-1, with_scores: true)
      end

      # Categories
      def add_category_id(phrase_id, category_id)
        Redis.current.sadd(category_set_key(phrase_id), category_id)
      end

      def get_categories(phrase_id)
        Redis.current.smembers(category_set_key(phrase_id))
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

      ### Helpers ### (consider refactoring with metaprogramming)
      def linkage_set_key(phrase_id)
        "#{self}:#{phrase_id}:linkage_set"
      end

      def category_set_key(phrase_id)
        "#{self}:#{phrase_id}:category_set"
      end

    end
    private_class_method :linkage_set_key, :category_set_key
  end
end
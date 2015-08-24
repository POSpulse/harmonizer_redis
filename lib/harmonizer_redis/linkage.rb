module HarmonizerRedis
  class Linkage < BaseObject
    attr_accessor :content, :phrase
    attr_reader :content_normalized

    def initialize(params)
      @id = params[:id]
      @content = params[:content]
      @content_normalized = HarmonizerRedis.normalize_string(@content)
    end

    def save #make sure that new phrase is saved
      #if phrase already exists : set to that phrase
      #otherwise : create a new phrase and set linkage:phrase to that phrase
      existing_phrase_id = HarmonizerRedis::Phrase.find_by_content(@content_normalized)
      if existing_phrase_id
        @phrase = existing_phrase_id
      else
        new_phrase = HarmonizerRedis::Phrase.new(@content_normalized)
        new_phrase.save
        @phrase = new_phrase.id
      end
      super()
    end

    # Return the top num_phrases most similar phrases
    class << self
      def get_true_label(linkage_id)
        PhraseGroup.get_label(self.get_phrase_group_id(linkage_id))
      end

      # option :show_changes => true will return list of changed phrases
      def set_true_label(linkage_id, new_label = nil, options = {})
        PhraseGroup.set_label(self.get_phrase_group_id(linkage_id), new_label)
        if options[:show_changes]
          PhraseGroup.get_phrase_list(self.get_phrase_group_id(linkage_id)).map { |x| Phrase.get_content(x) }
        end
      end

      def get_phrase_group_id(linkage_id)
        Phrase.get_phrase_group(get_phrase_id(linkage_id)).to_i
      end

      def get_phrase_id(linkage_id)
        Redis.current.get("#{self}:#{linkage_id}:phrase").to_i
      end

      def get_similarities(linkage_id, num_phrases)
        own_phrase_id = self.get_phrase_id(linkage_id)
        phrase_id_list = Redis.current.zrevrange("HarmonizerRedis::Phrase:#{own_phrase_id}",
            0, num_phrases, :with_scores => true)
        phrase_id_list.map do |phrase_id, score|
          unless Phrase.in_same_group?(own_phrase_id, phrase_id)
            [Phrase.get_content(phrase_id), PhraseGroup.get_label(Phrase.get_phrase_group(phrase_id)),
             score, phrase_id]
          end
        end
      end

      def merge_with_phrase(linkage_id, foreign_phrase_id)
        own_phrase_id = self.get_phrase_id(linkage_id)
        Phrase.merge_phrases(own_phrase_id, foreign_phrase_id)
      end
    end
  end
end

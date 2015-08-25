module HarmonizerRedis
  class Linkage < BaseObject
    attr_reader :id

    def initialize(params)
      if Redis.current.sismember("#{self.class}:set", "#{params[:id]}")
        raise "ID has already been used"
      end

      unless params[:id]
        raise "id must be given in params"
      end

      @id = params[:id]
      @content = params[:content]
      @corrected = params[:content]
      @category_id = params[:category_id]
    end

    def save # make sure that new phrase is saved
      # if phrase already exists : set to that phrase
      # otherwise : create a new phrase and set linkage:phrase to that phrase
      # linkage is also added to the category with certain id (can be used to divide tasks)
      unless @id && @content && @category_id
        raise "id, content, and category_id are not all set"
      end
      @content_normalized = HarmonizerRedis.normalize_string(@content)
      existing_phrase_id = HarmonizerRedis::Phrase.find_by_content(@content_normalized)
      if existing_phrase_id
        @phrase = existing_phrase_id
      else
        new_phrase = HarmonizerRedis::Phrase.new(@content_normalized)
        new_phrase.save
        @phrase = new_phrase.id
      end
      Category.add_linkage(@category_id, @id)
      super()
    end

    # Readers

    def content
      @content ||= Redis.current.get("#{self.class}:#{@id}:content")
    end

    def content_normalized
      @content_normalized ||= Redis.current.get("#{self.class}:#{@id}:content")
    end

    def category_id
      @category_id ||= Redis.current.get("#{self.class}:#{@id}:category_id")
    end

    def corrected
      @corrected ||= Redis.current.get("#{self.class}:#{@id}:corrected")
    end

    def phrase_id
      @phrase ||= Redis.current.get("#{self.class}:#{@id}:phrase")
    end

    # Writers

    def content=(value)
      unless Redis.current.sismember("#{self.class}:set", @id)
        @content = value
      else
        raise "Saved linkage content cannot be edited"
      end
    end

    def get_similarities(num_phrases)
      self_phrase_id = self.phrase_id
      phrase_id_list = Redis.current.zrevrange("HarmonizerRedis::Category:#{self.category_id}:#{self_phrase_id}:sims",
                                               0, num_phrases, :with_scores => true)
      phrase_id_list.map do |phrase_id, score|
        unless Phrase.in_same_group?(self_phrase_id, phrase_id)
          [Phrase.get_content(phrase_id), PhraseGroup.get_label(Phrase.get_phrase_group(phrase_id)),
           score, phrase_id]
        end
      end
    end

    private :phrase_id

    class << self
      def find(linkage_id)
        unless Redis.current.sismember("#{self}:set", "#{linkage_id}")
          return nil
        end
        linkage = self.new(id: linkage_id)
        linkage
      end

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

      def merge_with_phrase(linkage_id, foreign_phrase_id)
        own_phrase_id = self.get_phrase_id(linkage_id)
        Phrase.merge_phrases(own_phrase_id, foreign_phrase_id)
      end
    end
  end
end

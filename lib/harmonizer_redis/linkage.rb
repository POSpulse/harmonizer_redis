module HarmonizerRedis
  class Linkage < BaseObject
    attr_reader :id

    def initialize(params)
      unless params[:id]
        raise "id must be given in params"
      end

      if self.is_saved?
        # Make sure that user does not re use an old ID
        unless params[:content].nil? && params[:category_id].nil?
          raise "ID has already been used"
        end
      end

      @id = params[:id]
      @content = params[:content]
      @category_id = params[:category_id]
    end

    def save # make sure that new phrase is saved
      # if phrase already exists : set to that phrase
      # otherwise : create a new phrase and set linkage:phrase to that phrase
      # linkage is also added to the category with certain id (can be used to divide tasks)

      # Assert: all required fields have been set
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
      super()
      Category.add_linkage(self)
    end

    # Readers

    def content
      @content ||= self.class.get_content(@id)
    end

    def content_normalized
      @content_normalized ||= self.class.get_content_normalized(@id)
    end

    def category_id
      @category_id ||= self.class.get_category_id(@id)
    end

    def corrected
      label = Category.get_group_label(category_id, phrase_id)
      if label.nil?
        if Category.get_group_count(category_id, phrase_id)
          return content
        else
          '(LABEL NOT SET)'
        end
      else
        label
      end
    end

    def phrase_id
      @phrase ||= self.class.get_phrase_id(@id)
    end

    # Writers

    def content=(value)
      if self.is_saved?
        raise "Saved linkage content cannot be edited"
      else
        @content = value
      end
    end

    def category_id=(value)
      if self.is_saved?
        raise "Saved linkage category_id cannot be edited"
      else
        @category_id = value
      end
    end

    # Functionality

    def get_similarities(num_phrases)
      self_phrase_id = phrase_id
      # Check if Category has been calculated
      phrase_id_list = Redis.current.zrevrange("HarmonizerRedis::Category:#{self.category_id}:#{self_phrase_id}:sims",
                                               0, num_phrases, :with_scores => true)
      results = []
      phrase_id_list.each do |phrase_id, score|
        unless Category.in_same_group?(category_id, self_phrase_id, phrase_id)
          results << [Phrase.get_content(phrase_id), corrected, score, phrase_id.to_i]
        end
      end
      results
    end

    # Recommend possible labels for a linkage
    def recommend_labels
      existing_labels = Category.get_all_group_labels(category_id, phrase_id)
      other_linkages = Category.get_group_popular_linkages(category_id, phrase_id)
      existing_labels + other_linkages
    end

    def merge_with_phrase(phrase_id)
      Category.merge_phrase_groups(category_id, @id, phrase_id)
    end

    def set_corrected_label(label)
      Category.set_group_label(category_id, phrase_id, label)
    end

    # Helpers
    def is_category_changed?
      unless is_saved?
        raise "Linkage must be saved first"
      end
      Category.is_changed?(self.category_id)
    end

    def is_saved?
      self.class.is_linkage_saved?(@id)
    end

    class << self
      def find(linkage_id)
        unless is_linkage_saved?(linkage_id)
          return nil
        end
        self.new(id: linkage_id)
      end

      def is_linkage_saved?(linkage_id)
        Redis.current.sismember("#{self}:set", "#{linkage_id}")
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

      def get_category_id(linkage_id)
        Redis.current.get("#{self}:#{linkage_id}:category_id").to_i
      end

      def get_phrase_id(linkage_id)
        Redis.current.get("#{self}:#{linkage_id}:phrase").to_i
      end

      def get_content(linkage_id)
        Redis.current.get("#{self}:#{linkage_id}:content")
      end

      def get_content_normalized(linkage_id)
        Redis.current.get("#{self}:#{linkage_id}:content_normalized")
      end

      def merge_with_phrase(linkage_id, foreign_phrase_id)
        own_phrase_id = self.get_phrase_id(linkage_id)
        Phrase.merge_phrases(own_phrase_id, foreign_phrase_id)
      end

    end
  end
end

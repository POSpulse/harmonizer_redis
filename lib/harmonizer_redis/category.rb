module HarmonizerRedis
  class Category < BaseObject
    attr_reader :id
    def initialize(id)
      @id = id
    end

    def save
      super()
    end

    class << self
      # Add linkage to category group
      def add_linkage(linkage)
        category_id = linkage.category_id
        linkage_id = linkage.id
        phrase_id = linkage.phrase_id

        unless self.valid?(category_id)
          new_category = self.new(category_id)
          new_category.save
        end

        self.add_to_linkage_set(category_id, linkage_id)
        self.add_to_phrase_set(category_id, phrase_id)

        set_changed(category_id, 1)
        set_calculated(category_id, 0)
        set_phrase_calculated(category_id, phrase_id, 0)

        # Creating/adding to a group
        add_group(category_id, phrase_id)

        # Adding linkage to the phrase
        Phrase.add_linkage(phrase_id, linkage_id, category_id)
      end

      # Gets list of linkages included in category group
      def get_linkage_list(category_id)
        Redis.current.smembers("#{self}:#{category_id}:linkage_set")
      end

      def get_phrase_list(category_id)
        Redis.current.smembers("#{self}:#{category_id}:phrase_set")
      end

      def get_matrices(category_id, phrase_id_list)
        matrices_list = []
        if !matrices_calculated?(category_id) || changed?(category_id)
          phrase_id_list.each do |id|
            content = Phrase.get_content(id)
            new_matrix = IdfScorer.serialize_matrix(IdfScorer.calc_soft_matrix(content))
            Redis.current.set("HarmonizerRedis::Phrase:#{id}:matrix", new_matrix)
            matrices_list << new_matrix
          end
          set_calculated(category_id, 1)
        else
          phrase_id_list.each do |phrase_id|
            matrices_list << Phrase.get_matrix(phrase_id)
          end
        end
        matrices_list
      end

      # Set the category as "unchanged". Should be called after Category similarities
      # have been calculated
      def reset_changed(category_id)
        set_changed(category_id, 0)
      end

      # Check to see if id is valid
      def valid?(category_id)
        Redis.current.sismember("#{self}:set", "#{category_id}")
      end

      def changed?(category_id)
        !Redis.current.getbit("#{self}:changed", category_id).zero?
      end

      def matrices_calculated?(category_id)
        !Redis.current.getbit("#{self}:calculated", category_id).zero?
      end

      def is_phrase_calculated?(category_id, phrase_id)
        !Redis.current.getbit("#{self}:#{category_id}:calculated", phrase_id).zero?
      end

      # Merge 2 phrases' groups
      def merge_phrase_groups(category_id, phrase_a_id, phrase_b_id)
        group_a = get_group_key(category_id, phrase_a_id)
        group_b = get_group_key(category_id, phrase_b_id)
        # Error either group does not exist
        if group_a.nil? || group_b.nil?
          raise 'Invalid Phrase ID(s) given!'
        end
        # Do nothing if both are already in the same group
        if group_a == group_b
          return
        end
        label_a = get_group_label(category_id, phrase_a_id)
        label_b = get_group_label(category_id, phrase_b_id)

        # if label_a and label_b both exist
        unless label_a.nil? ^ label_b.nil?
          # if label_a and label_b are not the same label
          if label_a != label_b
            # delete both labels due to conflict
            Redis.current.del(label_a, label_b)
          else # both labels are the same
            # delete only the label that belongs to the group getting destroyed
            Redis.current.del(label_b)
          end
        end

        # if only label_b exists
        if label_a.nil? && !label_b.nil?
          merge_phrase_group_helper(category_id, group_a, group_b)
          Redis.current.del(group_a)
        else # if only label_a exists
          merge_phrase_group_helper(category_id, group_b, group_a)
          Redis.current.del(group_b)
        end

      end

      ### Getting popular linkages and generating possible labels

      def get_group_popular_linkages(category_id, phrase_id, number = 5)
        phrases = get_group(category_id, phrase_id)
        linkages = []
        phrases.each do |id|
          linkages += Phrase.get_popular_linkages(id)
        end
        linkages.sort_by! { |entry| -1 * entry[-1] }
        linkages.first(number)
      end

      def get_all_group_labels(category_id, phrase_id)
        phrases_in_group = get_group(category_id, phrase_id)
        categories = []
        phrases_in_group.each do |phrase_id|
          categories += Phrase.get_categories(phrase_id)
        end
        labels = Hash.new { |hash, key| hash[key] = 0.0 }
        categories.each do |category_id|
          phrases_in_group.each do |phrase_id|
            group_label = get_group_label(category_id, phrase_id)
            unless group_label.nil?
              labels[group_label] += Phrase.get_linkage_count(phrase_id)
            end
          end
        end
        labels.to_a.sort_by { |x| x[-1] }
      end

      def set_group_label(category_id, phrase_id, label)
        Redis.current.set("#{get_group_key(category_id, phrase_id)}:label", label)
      end

      def get_group_label(category_id, phrase_id)
        Redis.current.get("#{get_group_key(category_id, phrase_id)}:label")
      end

      def get_group_count(category_id, phrase_id)
        Redis.current.scard(get_group_key(category_id, phrase_id))
      end

      def get_group(category_id, phrase_id)
        Redis.current.smembers(get_group_key(category_id, phrase_id))
      end

      def in_same_group?(category_id, phrase_a_id, phrase_b_id)
        get_group_key(category_id, phrase_a_id) == get_group_key(category_id, phrase_b_id)
      end

      ### Helpers ####
      def add_to_linkage_set(category_id, linkage_id)
        Redis.current.sadd("#{self}:#{category_id}:linkage_set", linkage_id)
      end

      def add_to_phrase_set(category_id, phrase_id)
        Redis.current.sadd("#{self}:#{category_id}:phrase_set", phrase_id)
      end

      def set_changed(category_id, value)
        Redis.current.setbit("#{self}:changed", category_id, value)
      end

      def set_calculated(category_id, value)
        Redis.current.setbit("#{self}:calculated", category_id, value)
      end

      def set_phrase_calculated(category_id, phrase_id, value)
        Redis.current.setbit("#{self}:#{category_id}:calculated", phrase_id, value)
      end

      def add_group(category_id, phrase_id)
        group_key = get_group_key(category_id, phrase_id)
        if group_key.nil?
          group_key = create_group(category_id, phrase_id)
          Redis.current.sadd(group_key, phrase_id)
        end
      end

      def create_group(category_id, phrase_id)
        new_group_id = Redis.current.incr("#{self}:#{category_id}:group_count") - 1
        new_group_key = "#{self}:#{category_id}:group:#{new_group_id}"
        set_phrase_group(category_id, phrase_id, new_group_key)
        new_group_key
      end

      def get_group_key(category_id, phrase_id)
        Redis.current.get("#{self}:#{category_id}:#{phrase_id}:group")
      end

      def change_phrases_group(category_id, old_group_key, new_group_key)
        phrase_list = Redis.current.smembers(old_group_key)
        phrase_list.each do |phrase_id|
          set_phrase_group(category_id, phrase_id, new_group_key)
        end
      end

      def merge_phrase_group_helper(category_id, source_group, dest_group)
        Redis.current.sunionstore(dest_group, source_group, dest_group)
        change_phrases_group(category_id, source_group, dest_group)
        Redis.current.del(source_group)
      end

      def set_phrase_group(category_id, phrase_id, group_key)
        Redis.current.set("#{self}:#{category_id}:#{phrase_id}:group", group_key)
      end

    end
    private_class_method :set_changed, :create_group, :get_group_key, :set_phrase_group, :change_phrases_group
  end
end
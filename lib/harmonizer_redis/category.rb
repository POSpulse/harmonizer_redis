module HarmonizerRedis
  class Category < BaseObject
    def initialize(category_id)
      @id = category_id
    end

    def save
      super()
    end

    class << self
      # Add linkage to category group
      def add_linkage(category_id, linkage_id, phrase_id, content)
        unless self.is_valid?(category_id)
          new_category = self.new(category_id)
          new_category.save
        end
        Redis.current.sadd("#{self}:#{category_id}:linkage_set", linkage_id)
        set_changed(category_id, 1)

        # Creating/adding to a group
        group_key = get_group_key(category_id, phrase_id)
        if group_key.nil?
          group_key = create_group(category_id, phrase_id)
          Redis.current.sadd(group_key, phrase_id)
          Redis.current.set("#{group_key}:label", content)
        end
      end

      # Gets list of linkages included in category group
      def get_linkage_list(category_id)
        Redis.current.smembers("#{self}:#{category_id}:linkage_set").map { |x| x.to_i }
      end

      # Set the category as "unchanged". Should be called after Category similarities
      # have been calculated
      def reset_changed(category_id)
        set_changed(category_id, 0)
      end

      # Check to see if id is valid
      def is_valid?(category_id)
        Redis.current.sismember("#{self}:set", "#{category_id}")
      end

      def is_changed?(category_id)
        !Redis.current.getbit("#{self}:changed", category_id).zero?
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

        # if label_a and label_b are both exist
        unless label_a.nil? ^ label_b.nil?
          # if label_a and label_b are not the same label
          if label_a != label_b
            # delete both labels due to conflict
            Redis.current.del(label_a, label_b)
          else
            # delete only the label that belongs to the group getting destroyed
            Redis.current.del(label_b)
          end
        end

        # if label_a is empty and label_b exists
        if label_a.nil? && !label_b.nil?
          merge_phrase_group_helper(category_id, group_a, group_b)
          Redis.current.del(group_a)
        else # label_b is empty and label_a exists, or both are empty, or both existed
          merge_phrase_group_helper(category_id, group_b, group_a)
          Redis.current.del(group_b)
        end

      end

      def set_group_label(category_id, phrase_id, label)
        Redis.current.set("#{get_group_key(category_id, phrase_id)}:label", label)
      end

      def get_group_label(category_id, phrase_id)
        Redis.current.get("#{get_group_key(category_id, phrase_id)}:label")
      end

      def in_same_group?(category_id, phrase_a_id, phrase_b_id)
        get_group_key(category_id, phrase_a_id) == get_group_key(category_id, phrase_b_id)
      end

      ### Helpers ####
      def set_changed(category_id, value)
        Redis.current.setbit("#{self}:changed", category_id, value)
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
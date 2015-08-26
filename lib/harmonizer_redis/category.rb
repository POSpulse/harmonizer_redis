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
      def add_linkage(category_id, linkage_id)
        unless self.is_valid?(category_id)
          new_category = self.new(category_id)
          new_category.save
        end
        Redis.current.sadd("#{self}:#{category_id}:linkage_set", linkage_id)
        Redis.current.setbit("#{self}:changed", category_id, 1)
      end

      # Gets list of linkages included in category group
      def get_linkage_list(category_id)
        Redis.current.smembers("#{self}:#{category_id}:linkage_set").map { |x| x.to_i }
      end

      # Set the category as "unchanged". Should be called after Category similarities
      # have been calculated
      def reset_changed(category_id)
        Redis.current.setbit("#{self}:changed", category_id, 0)
      end

      # Check to see if id is valid
      def is_valid?(category_id)
        Redis.current.sismember("#{self}:set", "#{category_id}")
      end

      def is_changed?(category_id)
        !Redis.current.getbit("#{self}:changed", category_id).zero?
      end
    end

  end
end
module HarmonizerRedis
  class Category < BasicObject
    def initialize(category_id)
      @id = category_id
    end

    def save
      super()
    end

    class << self
      # Add linkage to category group
      def add_linkage(category_id, linkage_id)
        Redis.current.sadd("#{self}:#{category_id}:linkage_set", linkage_id)
      end

      # Gets list of linkages included in category group
      def get_linkage_list(category_id)
        Redis.current.smembers("#{self}:#{category_id}:linkage_set").map { |x| x.to_i }
      end

      # Check to see if id is valid
      def is_valid?(category_id)
        Redis.current.sismember("#{self}:set", "#{category_id}")
      end
    end

  end
end
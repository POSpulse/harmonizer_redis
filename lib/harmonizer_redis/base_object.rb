module HarmonizerRedis
  class BaseObject
    attr_accessor :id

    def generate_id
      Redis.current.incr("#{self.class}").to_i - 1
    end

    def save
      #creates a new id only when object is being saved
      klass = "#{self.class}"
      new_id = @id || self.generate_id
      self.instance_variables.each do |variable|
        var_name = variable.to_s[1..-1]
        Redis.current.set("#{klass}:#{new_id}:#{var_name}", instance_variable_get(variable))
      end

      @id = new_id

      #add id to HarmonizerRedis::ClassName:set
      Redis.current.sadd("#{klass}:set", @id)
    end
  end
end

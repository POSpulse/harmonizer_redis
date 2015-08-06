module HarmonizerRedis
  class BaseObject
    attr_accessor :id

    def initialize
      @id = Redis.current.incr("#{self.class}:counter").to_i
    end

    def save
      self.instance_variables.each do |variable|
        var_name = variable.to_s[1..-1]
        if var_name != 'id'
          Redis.current.set("#{self.class}:#{@id}:#{var_name}", instance_variable_get(variable))
        end
      end

      #add id to HarmonizerRedis::ClassName:set
      Redis.current.sadd("#{self.class}:set", @id)

    end
  end
end

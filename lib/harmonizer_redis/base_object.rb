class BaseObject
  attr_accessor :id

  def self.new(*args)
    @id = Redis::Object.redis.incr("#{self.class}:count")
    counter = Redis::Counter.new(self.class.to_s)
    super
  end

  def save
    self.instance_variables.each do |variable|
      var_name = variable.to_s[1..-1]
      Redis::Object.redis.set("#{self.class}:#{id}:#{var_name}", self.instance_variable_get(var_name))
    end
  end
end
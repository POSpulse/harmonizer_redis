module HarmonizerRedis
  class Phrase < BaseObject
    attr_accessor :content

    def initialize(content)
      @content = content
    end

    def save
      super()
      Redis.current.set("#{self.class}:[#{@content}]", "#{self.class}:#{@id}")
      Redis.current.sadd('HarmonizerRedis::Phrase:content_set', @content)
    end

    def self.find_by_content(content)
      Redis.current.get("#{self}:[#{content}]")
    end

  end
end
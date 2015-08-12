module HarmonizerRedis

  class PhraseGroup < BaseObject
    attr_accessor :label, :init_phrase_id

    def initialize(phrase_id)
      @init_phrase_id = phrase_id
      @label = HarmonizerRedis::Phrase.get_content(phrase_id)
    end

    def save
      super()
      Redis.current.sadd("#{self.class}:#{@id}:phrase_set", @init_phrase_id)
      HarmonizerRedis::Phrase.set_phrase_group(@init_phrase_id, @id)
    end

    def self.set_label(phrase_group_id, label)
      Redis.current.set("#{self}:#{phrase_group_id}:label", label)
    end

    def self.get_label(phrase_group_id)
      Redis.current.get("#{self}:#{phrase_group_id}:label")
    end

    #merging 2 groups with their ids
    def self.merge(old_group_id, new_group_id, label = nil)
      #finding larger set to set as union result so that fewer changes have to be made
      old_group_key = "#{self}:#{old_group_id}:phrase_set"
      new_group_key = "#{self}:#{new_group_id}:phrase_set"
      if label.nil?
        label = self.get_label(new_group_id)
      end
      old_group_size = Redis.current.scard(old_group_key)
      new_group_size = Redis.current.scard(new_group_key)
      destination_id, source_id = old_group_size > new_group_size ?
          [old_group_id, new_group_id] : [new_group_id, old_group_id]
      destination_key = "#{self}:#{destination_id}:phrase_set"


      Redis.current.smembers("#{self}:#{source_id}:phrase_set").each do |phrase|
        HarmonizerRedis::Phrase.set_phrase_group(phrase, destination_id)
      end

      Redis.current.sunionstore(destination_key, old_group_key, new_group_key)
      self.set_label(destination_id, label)

      self.delete(source_id)

    end

    def self.delete(phrase_group_id)
      base = "#{self}:#{phrase_group_id}"
      Redis.current.del("#{base}:label", "#{base}:phrase_set", "#{base}:init_phrase_id")
    end
  end
end
#as long as 2 things that are same selected belong together
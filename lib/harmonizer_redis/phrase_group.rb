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
      HarmonizerRedis::TfidfTable.add_document(@init_phrase_id)
      Redis.current.pipelined do
        @label.split.each do |word|
          Redis.current.sadd("#{self.class}:#{@id}:word_set", word)
        end
      end
    end

    def self.set_label(phrase_group_id, label)
      Redis.current.set("#{self}:#{phrase_group_id}:label", label)
    end

    def self.get_label(phrase_group_id)
      Redis.current.get("#{self}:#{phrase_group_id}:label")
    end

    def self.phrase_set_key(phrase_group_id)
      "#{self}:#{phrase_group_id}:phrase_set"
    end

    def self.word_set_key(phrase_group_id)
      "#{self}:#{phrase_group_id}:word_set"
    end

    #merging 2 groups with their ids
    def self.merge(old_group_id, new_group_id, label = nil)
      #finding larger set to set as union result so that fewer changes have to be made
      old_phrase_set = self.phrase_set_key(old_group_id)
      new_phrase_set = self.phrase_set_key(new_group_id)
      old_word_set = self.word_set_key(old_group_id)
      new_word_set = self.word_set_key(new_group_id)
      if label.nil?
        label = self.get_label(new_group_id)
      end
      old_group_size = Redis.current.scard(old_phrase_set)
      new_group_size = Redis.current.scard(new_phrase_set)
      destination_id, source_id = old_group_size > new_group_size ?
          [old_group_id, new_group_id] : [new_group_id, old_group_id]
      destination_phrase_set = self.phrase_set_key(destination_id)
      destination_word_set = self.word_set_key(destination_id)


      Redis.current.smembers("#{self}:#{source_id}:phrase_set").each do |phrase|
        HarmonizerRedis::Phrase.set_phrase_group(phrase, destination_id)
      end

      #Combine the 2 sets of Phrases
      Redis.current.sunionstore(destination_phrase_set, old_phrase_set, new_phrase_set)
      #Set label for the new group
      self.set_label(destination_id, label)
      #Combine the 2 sets of Words
      Redis.current.sunionstore(destination_word_set, old_word_set, new_word_set)
      #Decrement count of documents word exists in due to combination
      Redis.current.sinter(old_word_set, new_word_set).each do |word|
        HarmonizerRedis::TfidfTable.decr_doc_count(word)
      end

      self.delete(source_id)

    end

    def self.delete(phrase_group_id)
      base = "#{self}:#{phrase_group_id}"
      Redis.current.del("#{base}:label", "#{base}:phrase_set", "#{base}:init_phrase_id", "#{base}:word_set")
    end
  end
end
#as long as 2 things that are same selected belong together